-- Парсер принимает договорённый конверт. Ошибка JSON/cast откатывает транзакцию.
CREATE VIEW demo_stg.v_event_parsed AS
SELECT topic, kafka_partition, kafka_offset, batch_id,
       (event_json::json ->> 'event_id')::text AS event_id,
       (event_json::json ->> 'event_type')::text AS event_type,
       (event_json::json ->> 'entity_id')::text AS entity_id,
       (event_json::json ->> 'entity_version')::bigint AS entity_version,
       (event_json::json ->> 'op')::text AS op,
       (event_json::json ->> 'event_time')::timestamptz AS event_time,
       (event_json::json -> 'payload')::text AS payload,
       event_json
FROM demo_stg.kafka_event;

-- Один writer / fence обязателен. Вызов происходит внутри единой транзакции GP;
-- никакого внешнего commit Kafka или сетевого вызова эта функция не выполняет.
-- Статус READY устанавливает оркестратор только после полной загрузки batch.
CREATE OR REPLACE FUNCTION demo_ods.apply_batch(p_batch_id bigint)
RETURNS void AS $$
DECLARE v_bad bigint;
BEGIN
  IF (SELECT count(*) FROM demo_stg.batch_control WHERE batch_id=p_batch_id AND status='APPLIED') = 1 THEN RETURN; END IF;
  IF (SELECT count(*) FROM demo_stg.batch_control WHERE batch_id=p_batch_id AND status='READY') <> 1 THEN
    RAISE EXCEPTION 'batch % is not READY', p_batch_id;
  END IF;

  SELECT count(*) INTO v_bad FROM demo_stg.v_event_parsed e WHERE e.batch_id=p_batch_id AND (
    e.event_id IS NULL OR e.event_type IS NULL OR e.event_type NOT IN ('product','store','shipment','return') OR
    e.entity_id IS NULL OR e.entity_id !~ '^[A-Za-z0-9_-]+$' OR
    e.entity_version IS NULL OR e.entity_version<1 OR e.op IS NULL OR e.op NOT IN ('U','D') OR
    e.event_time IS NULL OR e.payload IS NULL OR e.payload='null' OR
    (e.payload::json ->> (e.event_type || '_id')) IS DISTINCT FROM e.entity_id OR
    (e.event_type='product' AND e.op='U' AND ((e.payload::json ->> 'product_name') IS NULL OR (e.payload::json ->> 'category') IS NULL)) OR
    (e.event_type='store' AND e.op='U' AND ((e.payload::json ->> 'store_name') IS NULL OR (e.payload::json ->> 'region') IS NULL)) OR
    (e.event_type IN ('shipment','return') AND (
      (e.payload::json ->> 'business_date') IS NULL OR
      (e.payload::json ->> 'quantity') IS NULL OR (e.payload::json ->> 'unit_price') IS NULL OR
      (e.payload::json ->> 'currency') IS DISTINCT FROM 'RUB' OR
      (e.payload::json ->> 'quantity')::bigint < 0 OR (e.payload::json ->> 'unit_price')::numeric < 0)) OR
    (e.event_type='shipment' AND ((e.payload::json ->> 'product_id') !~ '^[A-Za-z0-9_-]+$' OR (e.payload::json ->> 'store_id') !~ '^[A-Za-z0-9_-]+$' OR (e.payload::json ->> 'product_id') IS NULL OR (e.payload::json ->> 'store_id') IS NULL)) OR
    (e.event_type='return' AND ((e.payload::json ->> 'shipment_id') !~ '^[A-Za-z0-9_-]+$' OR (e.payload::json ->> 'shipment_id') IS NULL))
  );
  IF v_bad>0 THEN RAISE EXCEPTION 'batch % contains % invalid events',p_batch_id,v_bad; END IF;

  SELECT count(*) INTO v_bad FROM (
    SELECT event_id FROM demo_stg.v_event_parsed WHERE batch_id=p_batch_id
    GROUP BY event_id HAVING count(DISTINCT event_json)>1
  ) x;
  IF v_bad>0 THEN RAISE EXCEPTION 'conflicting duplicate event IDs: %',v_bad; END IF;
  SELECT count(*) INTO v_bad FROM demo_stg.v_event_parsed e JOIN demo_ods.event o USING (event_id)
    WHERE e.batch_id=p_batch_id AND e.event_json<>o.event_document;
  IF v_bad>0 THEN RAISE EXCEPTION 'event IDs reused with different content: %',v_bad; END IF;
  SELECT count(*) INTO v_bad FROM (
    SELECT event_type,entity_id,entity_version FROM (
      SELECT event_type,entity_id,entity_version,event_id FROM demo_ods.event
      UNION ALL SELECT event_type,entity_id,entity_version,event_id FROM demo_stg.v_event_parsed WHERE batch_id=p_batch_id
    ) v GROUP BY event_type,entity_id,entity_version HAVING count(DISTINCT event_id)>1
  ) q;
  IF v_bad>0 THEN RAISE EXCEPTION 'business version reused by different events: %',v_bad; END IF;

  INSERT INTO demo_ods.event (event_id,event_type,entity_id,entity_version,op,event_time,load_dts,record_source,batch_id,payload,event_document)
  SELECT e.event_id,e.event_type,e.entity_id,e.entity_version,e.op,e.event_time,now(),e.topic,e.batch_id,e.payload,e.event_json
  FROM (SELECT p.*,row_number() OVER(PARTITION BY event_id ORDER BY topic,kafka_partition,kafka_offset) rn
        FROM demo_stg.v_event_parsed p WHERE batch_id=p_batch_id) e
  WHERE e.rn=1 AND NOT EXISTS (SELECT 1 FROM demo_ods.event o WHERE o.event_id=e.event_id);

  INSERT INTO demo_vault.hub_product SELECT DISTINCT md5('product:'||e.entity_id),e.entity_id,now(),e.record_source
    FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='product'
    AND NOT EXISTS (SELECT 1 FROM demo_vault.hub_product h WHERE h.product_id=e.entity_id);
  INSERT INTO demo_vault.hub_store SELECT DISTINCT md5('store:'||e.entity_id),e.entity_id,now(),e.record_source
    FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='store'
    AND NOT EXISTS (SELECT 1 FROM demo_vault.hub_store h WHERE h.store_id=e.entity_id);
  INSERT INTO demo_vault.hub_shipment SELECT DISTINCT md5('shipment:'||e.entity_id),e.entity_id,now(),e.record_source
    FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='shipment'
    AND NOT EXISTS (SELECT 1 FROM demo_vault.hub_shipment h WHERE h.shipment_id=e.entity_id);
  INSERT INTO demo_vault.hub_return SELECT DISTINCT md5('return:'||e.entity_id),e.entity_id,now(),e.record_source
    FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='return'
    AND NOT EXISTS (SELECT 1 FROM demo_vault.hub_return h WHERE h.return_id=e.entity_id);

  INSERT INTO demo_vault.link_shipment
  SELECT DISTINCT md5('shiplink:'||e.entity_id||':'||(e.payload::json->>'product_id')||':'||(e.payload::json->>'store_id')),
   md5('shipment:'||e.entity_id),md5('product:'||(e.payload::json->>'product_id')),md5('store:'||(e.payload::json->>'store_id')),now(),e.record_source
  FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='shipment'
    AND NOT EXISTS (SELECT 1 FROM demo_vault.link_shipment l WHERE l.link_hk=md5('shiplink:'||e.entity_id||':'||(e.payload::json->>'product_id')||':'||(e.payload::json->>'store_id')));
  INSERT INTO demo_vault.link_return
  SELECT DISTINCT md5('returnlink:'||e.entity_id||':'||(e.payload::json->>'shipment_id')),
   md5('return:'||e.entity_id),md5('shipment:'||(e.payload::json->>'shipment_id')),now(),e.record_source
  FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='return'
    AND NOT EXISTS (SELECT 1 FROM demo_vault.link_return l WHERE l.link_hk=md5('returnlink:'||e.entity_id||':'||(e.payload::json->>'shipment_id')));

  INSERT INTO demo_vault.sat_product
  SELECT md5('product:'||e.entity_id),e.event_id,e.entity_version,e.op,e.event_time,e.load_dts,e.record_source,md5(e.op||':'||e.payload),e.payload::json->>'product_name',e.payload::json->>'category'
  FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='product' AND NOT EXISTS (SELECT 1 FROM demo_vault.sat_product s WHERE s.event_id=e.event_id);
  INSERT INTO demo_vault.sat_store
  SELECT md5('store:'||e.entity_id),e.event_id,e.entity_version,e.op,e.event_time,e.load_dts,e.record_source,md5(e.op||':'||e.payload),e.payload::json->>'store_name',e.payload::json->>'region'
  FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='store' AND NOT EXISTS (SELECT 1 FROM demo_vault.sat_store s WHERE s.event_id=e.event_id);
  INSERT INTO demo_vault.sat_shipment
  SELECT md5('shipment:'||e.entity_id),md5('shiplink:'||e.entity_id||':'||(e.payload::json->>'product_id')||':'||(e.payload::json->>'store_id')),
   e.event_id,e.entity_version,e.op,e.event_time,e.load_dts,e.record_source,md5(e.op||':'||e.payload),e.payload::json->>'order_id',
   (e.payload::json->>'business_date')::date,(e.payload::json->>'quantity')::bigint,(e.payload::json->>'unit_price')::numeric(18,2),e.payload::json->>'currency'
  FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='shipment' AND NOT EXISTS (SELECT 1 FROM demo_vault.sat_shipment s WHERE s.event_id=e.event_id);
  INSERT INTO demo_vault.sat_return
  SELECT md5('return:'||e.entity_id),md5('returnlink:'||e.entity_id||':'||(e.payload::json->>'shipment_id')),
   e.event_id,e.entity_version,e.op,e.event_time,e.load_dts,e.record_source,md5(e.op||':'||e.payload),
   (e.payload::json->>'business_date')::date,(e.payload::json->>'quantity')::bigint,(e.payload::json->>'unit_price')::numeric(18,2),e.payload::json->>'currency'
  FROM demo_ods.event e WHERE e.batch_id=p_batch_id AND e.event_type='return' AND NOT EXISTS (SELECT 1 FROM demo_vault.sat_return s WHERE s.event_id=e.event_id);

  UPDATE demo_stg.batch_control SET status='APPLIED' WHERE batch_id=p_batch_id;
END;
$$ LANGUAGE plpgsql;
