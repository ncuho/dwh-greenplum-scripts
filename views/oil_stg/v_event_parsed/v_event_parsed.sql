-- Контекст миграции: AS IS / TO BE.
-- Назначение: Извлекает поля envelope и payload без потери исходного JSON.
-- AS IS: oil_stg.v_event_parsed; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
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
