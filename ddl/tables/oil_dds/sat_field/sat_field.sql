-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит версии атрибутов field, происхождение, порядок версий и операции изменения.
-- AS IS: oil_dds.sat_field; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_dds.sat_field (
    field_hk text NOT NULL,
    event_id text NOT NULL,
    entity_version bigint NOT NULL,
    op text NOT NULL,
    event_time timestamptz NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    hashdiff text NOT NULL,
    field_name text,
    region text)
DISTRIBUTED BY (field_hk);
