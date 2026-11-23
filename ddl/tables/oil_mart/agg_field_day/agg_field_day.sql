-- Контекст миграции: AS IS / TO BE.
-- Назначение: Суммирует тонны и активные скважино-дни по месторождению и дате.
-- AS IS: oil_mart.agg_field_day; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_mart.agg_field_day (
    production_date date NOT NULL,
    field_hk text NOT NULL,
    field_name text NOT NULL,
    region text NOT NULL,
    oil_tonnes numeric(22, 3) NOT NULL,
    producing_well_days bigint NOT NULL,
    oil_per_well_day numeric(22, 6))
DISTRIBUTED BY (field_hk);
