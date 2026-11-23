-- Назначение: Read-only разбор доставки и расшифровки исходного события.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
-- Greenplum: inspect event delivery and decoded business fields; read-only.
SELECT
    e.topic,
    e.kafka_partition,
    e.kafka_offset,
    b.status AS batch_status,
    e.event_id,
    e.event_type,
    e.entity_id,
    e.entity_version,
    e.op
FROM oil_stg.v_event_parsed e
JOIN oil_stg.batch_control b ON b.batch_id = e.batch_id
ORDER BY e.kafka_partition, e.kafka_offset
LIMIT 25;
