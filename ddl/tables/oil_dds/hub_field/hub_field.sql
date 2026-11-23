-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит устойчивый бизнес-ключ и hash key сущности field; атрибуты вынесены в satellites.
-- AS IS: oil_dds.hub_field; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_dds.hub_field (
    field_hk text NOT NULL,
    field_id text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (field_hk);
