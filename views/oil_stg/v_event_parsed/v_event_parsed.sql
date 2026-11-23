-- Назначение: Разбирает envelope JSON в STG: тип, ID, версию, операцию, время и payload без изменения исходного документа.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE VIEW oil_stg.v_event_parsed AS
SELECT
    topic,
    kafka_partition,
    kafka_offset,
    batch_id,
    event_json,
    (event_json::json ->> 'schema_version')::integer schema_version,
    event_json::json ->> 'event_id' event_id,
    event_json::json ->> 'event_type' event_type,
    event_json::json ->> 'entity_id' entity_id,
    (event_json::json ->> 'entity_version')::bigint entity_version,
    event_json::json ->> 'op' op,
    (event_json::json ->> 'event_time')::timestamptz event_time,
    (event_json::json -> 'payload')::text payload
FROM
    oil_stg.event_log;
