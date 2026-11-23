-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит следующий принятый offset каждой исходной Kafka-партиции.
-- AS IS: oil_stg.kafka_checkpoint; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_stg.kafka_checkpoint (
    topic text NOT NULL,
    kafka_partition integer NOT NULL,
    next_offset bigint NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (topic, kafka_partition))
DISTRIBUTED BY (topic, kafka_partition);
