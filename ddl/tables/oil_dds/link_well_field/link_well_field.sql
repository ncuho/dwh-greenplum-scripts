-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит историю связи well_field через hash keys связанных hubs.
-- AS IS: oil_dds.link_well_field; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_dds.link_well_field (
    link_hk text NOT NULL,
    well_hk text NOT NULL,
    field_hk text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (well_hk);
