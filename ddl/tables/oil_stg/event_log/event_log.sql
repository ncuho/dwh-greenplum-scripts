-- Контекст миграции: AS IS / TO BE.
-- Назначение: Сохраняет JSON доставок с topic, partition, offset и исходной партией.
-- AS IS: oil_stg.event_log; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_stg.event_log (
    topic text NOT NULL,
    kafka_partition integer NOT NULL,
    kafka_offset bigint NOT NULL,
    batch_id bigint NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),
    event_json text NOT NULL,
    PRIMARY KEY (topic, kafka_partition, kafka_offset))
DISTRIBUTED BY (topic, kafka_partition);
