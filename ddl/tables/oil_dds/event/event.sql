-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит принятые event_id, версии сущностей, операции U/D и исходный документ.
-- AS IS: oil_dds.event; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_dds.event (
    event_id text PRIMARY KEY,
    event_type text NOT NULL,
    entity_id text NOT NULL,
    entity_version bigint NOT NULL,
    op text NOT NULL,
    event_time timestamptz NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    batch_id bigint NOT NULL,
    payload text NOT NULL,
    event_document text NOT NULL)
DISTRIBUTED BY (event_id);
