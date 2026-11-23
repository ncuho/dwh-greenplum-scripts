-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит отклонённые события; непустой reject блокирует выпуск.
-- AS IS: oil_stg.event_reject; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_stg.event_reject (
    topic text,
    kafka_partition integer,
    kafka_offset bigint,
    event_json text,
    reason text NOT NULL,
    rejected_at timestamptz NOT NULL DEFAULT now())
DISTRIBUTED BY (topic, kafka_partition);
