-- Контекст миграции: AS IS / TO BE.
-- Назначение: Связывает суточную добычу с действовавшими версиями измерений.
-- AS IS: oil_mart.fact_well_day; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_mart.fact_well_day (
    production_hk text NOT NULL,
    well_hk text NOT NULL,
    field_hk text NOT NULL,
    production_date date NOT NULL,
    well_version bigint NOT NULL,
    field_version bigint NOT NULL,
    status text NOT NULL,
    oil_tonnes numeric(18, 3) NOT NULL)
DISTRIBUTED BY (well_hk);
