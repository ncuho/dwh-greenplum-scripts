-- Контекст миграции: AS IS / TO BE.
-- Назначение: Формирует SCD2-версии месторождений с интервалом действия.
-- AS IS: oil_mart.dim_field; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_mart.dim_field (
    field_hk text NOT NULL,
    entity_version bigint NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_to timestamptz,
    field_name text,
    region text,
    is_deleted boolean NOT NULL)
DISTRIBUTED BY (field_hk);
