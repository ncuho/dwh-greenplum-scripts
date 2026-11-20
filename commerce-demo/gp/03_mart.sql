-- Срез последней версии сущности. Опоздавшая более старая версия хранится
-- в Vault, но не откатывает текущий факт.
CREATE VIEW demo_vault.v_shipment_current AS
SELECT * FROM (
 SELECT s.*,row_number() OVER(PARTITION BY s.shipment_hk ORDER BY s.entity_version DESC,s.event_id DESC) AS rn
 FROM demo_vault.sat_shipment s
) q WHERE q.rn=1 AND q.op='U';

CREATE VIEW demo_vault.v_return_current AS
SELECT * FROM (
 SELECT s.*,row_number() OVER(PARTITION BY s.return_hk ORDER BY s.entity_version DESC,s.event_id DESC) AS rn
 FROM demo_vault.sat_return s
) q WHERE q.rn=1 AND q.op='U';

-- Переопределение таблиц с одним GP-транзакционным commit. Single-writer обязателен.
-- Все ошибки RAISE откатывают пересчёт и сохраняют предыдущую публикацию GP.
CREATE OR REPLACE FUNCTION demo_dm.rebuild()
RETURNS void AS $$
DECLARE v_bad bigint;
BEGIN
 SELECT count(*) INTO v_bad FROM (
  SELECT product_hk,event_time FROM demo_vault.sat_product GROUP BY product_hk,event_time HAVING count(*)>1
  UNION ALL SELECT store_hk,event_time FROM demo_vault.sat_store GROUP BY store_hk,event_time HAVING count(*)>1
 ) q;
 IF v_bad>0 THEN RAISE EXCEPTION 'ambiguous dimension effective timestamps: %',v_bad; END IF;

 DELETE FROM demo_dm.fact_return;
 DELETE FROM demo_dm.fact_shipment;
 DELETE FROM demo_dm.dim_product;
 DELETE FROM demo_dm.dim_store;
 DELETE FROM demo_dm.sales_day;

 INSERT INTO demo_dm.dim_product
 SELECT product_hk,entity_version,event_time,
        lead(event_time) OVER(PARTITION BY product_hk ORDER BY event_time,entity_version,event_id),
        product_name,category,(op='D')
 FROM demo_vault.sat_product;
 INSERT INTO demo_dm.dim_store
 SELECT store_hk,entity_version,event_time,
        lead(event_time) OVER(PARTITION BY store_hk ORDER BY event_time,entity_version,event_id),
        store_name,region,(op='D')
 FROM demo_vault.sat_store;

 INSERT INTO demo_dm.fact_shipment
 SELECT s.shipment_hk,h.shipment_id,l.product_hk,l.store_hk,p.entity_version,t.entity_version,
        s.business_date,s.quantity,s.unit_price,s.currency,
        round(s.quantity*s.unit_price,2)::numeric(20,2)
 FROM demo_vault.v_shipment_current s
 JOIN demo_vault.hub_shipment h ON h.shipment_hk=s.shipment_hk
 JOIN demo_vault.link_shipment l ON l.link_hk=s.link_hk
 JOIN demo_dm.dim_product p ON p.product_hk=l.product_hk AND NOT p.is_deleted
      AND p.valid_from <= (s.business_date::timestamp AT TIME ZONE 'UTC')
      AND (p.valid_to IS NULL OR (s.business_date::timestamp AT TIME ZONE 'UTC') < p.valid_to)
 JOIN demo_dm.dim_store t ON t.store_hk=l.store_hk AND NOT t.is_deleted
      AND t.valid_from <= (s.business_date::timestamp AT TIME ZONE 'UTC')
      AND (t.valid_to IS NULL OR (s.business_date::timestamp AT TIME ZONE 'UTC') < t.valid_to);

 -- Проверяем каждую запись, а не только суммарное количество: отсутствие
 -- измерения и дубли нельзя компенсировать друг другом.
 SELECT count(*) INTO v_bad FROM demo_vault.v_shipment_current s
 WHERE (SELECT count(*) FROM demo_dm.fact_shipment f WHERE f.shipment_hk=s.shipment_hk)<>1;
 IF v_bad>0 THEN RAISE EXCEPTION 'missing or ambiguous shipment dimensions: %',v_bad; END IF;

 INSERT INTO demo_dm.fact_return
 SELECT r.return_hk,h.return_id,rln.shipment_hk,f.product_hk,f.store_hk,f.product_version,f.store_version,
        r.business_date,r.quantity,r.unit_price,r.currency,round(r.quantity*r.unit_price,2)::numeric(20,2)
 FROM demo_vault.v_return_current r
 JOIN demo_vault.hub_return h ON h.return_hk=r.return_hk
 JOIN demo_vault.link_return rln ON rln.link_hk=r.link_hk
 JOIN demo_dm.fact_shipment f ON f.shipment_hk=rln.shipment_hk;
 SELECT count(*) INTO v_bad FROM demo_vault.v_return_current r
 WHERE (SELECT count(*) FROM demo_dm.fact_return f WHERE f.return_hk=r.return_hk)<>1;
 IF v_bad>0 THEN RAISE EXCEPTION 'missing or ambiguous return parent: %',v_bad; END IF;
 SELECT count(*) INTO v_bad FROM demo_dm.fact_shipment s
 WHERE COALESCE((SELECT sum(r.quantity) FROM demo_dm.fact_return r WHERE r.shipment_hk=s.shipment_hk),0)>s.quantity;
 IF v_bad>0 THEN RAISE EXCEPTION 'returned quantity exceeds shipped quantity: %',v_bad; END IF;

 SELECT count(*) INTO v_bad FROM demo_dm.fact_return r JOIN demo_dm.fact_shipment s ON s.shipment_hk=r.shipment_hk
 WHERE r.currency<>s.currency OR r.business_date<s.business_date;
 IF v_bad>0 THEN RAISE EXCEPTION 'return currency or date inconsistent with shipment: %',v_bad; END IF;

 -- Независимая агрегация двух фактов предотвращает fan-out и повторную сумму.
 INSERT INTO demo_dm.sales_day
 WITH shipments AS (
  SELECT f.business_date,t.region,p.category,f.currency,sum(f.amount) amt,sum(f.quantity) qty
  FROM demo_dm.fact_shipment f
  JOIN demo_dm.dim_product p ON p.product_hk=f.product_hk AND p.entity_version=f.product_version
  JOIN demo_dm.dim_store t ON t.store_hk=f.store_hk AND t.entity_version=f.store_version
  GROUP BY 1,2,3,4
 ), returns AS (
  SELECT f.business_date,t.region,p.category,f.currency,sum(f.amount) amt,sum(f.quantity) qty
  FROM demo_dm.fact_return f
  JOIN demo_dm.dim_product p ON p.product_hk=f.product_hk AND p.entity_version=f.product_version
  JOIN demo_dm.dim_store t ON t.store_hk=f.store_hk AND t.entity_version=f.store_version
  GROUP BY 1,2,3,4
 )
 SELECT coalesce(s.business_date,r.business_date),coalesce(s.region,r.region),coalesce(s.category,r.category),coalesce(s.currency,r.currency),
  coalesce(s.amt,0)::numeric(22,2),coalesce(r.amt,0)::numeric(22,2),
  (coalesce(s.amt,0)-coalesce(r.amt,0))::numeric(22,2),coalesce(s.qty,0)::bigint,coalesce(r.qty,0)::bigint
 FROM shipments s FULL OUTER JOIN returns r ON s.business_date=r.business_date AND s.region=r.region AND s.category=r.category AND s.currency=r.currency;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW demo_dm.v_sales_dashboard AS
SELECT business_date,region,category,currency,shipment_amount,return_amount,net_amount,shipped_qty,returned_qty
FROM demo_dm.sales_day;
