-- Контекст миграции: AS IS / TO BE.
-- Назначение: Сохраняет происхождение доставки после объединения партий.
-- AS IS: oil_stg.batch_coalesce_event_map; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_stg.batch_coalesce_event_map (
    topic text NOT NULL,
    kafka_partition integer NOT NULL,
    kafka_offset bigint NOT NULL,
    original_batch_id bigint NOT NULL,
    coalesced_batch_id bigint NOT NULL,
    PRIMARY KEY (topic, kafka_partition, kafka_offset))
DISTRIBUTED BY (topic, kafka_partition);
