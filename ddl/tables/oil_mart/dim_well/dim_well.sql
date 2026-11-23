-- Контекст миграции: AS IS / TO BE.
-- Назначение: Формирует SCD2-версии скважин и принадлежность месторождению.
-- AS IS: oil_mart.dim_well; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_mart.dim_well (
    well_hk text NOT NULL,
    field_hk text NOT NULL,
    entity_version bigint NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    well_name text,
    status text,
    is_deleted boolean NOT NULL)
DISTRIBUTED BY (well_hk);
