-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит устойчивый бизнес-ключ и hash key сущности production_day; атрибуты вынесены в satellites.
-- AS IS: oil_dds.hub_production_day; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_dds.hub_production_day (
    production_hk text NOT NULL,
    production_id text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (production_hk);
