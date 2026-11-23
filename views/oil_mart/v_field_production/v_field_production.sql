-- Контекст миграции: AS IS / TO BE.
-- Назначение: Предоставляет бизнес-колонки отчёта добычи по месторождениям.
-- AS IS: oil_mart.v_field_production; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE VIEW oil_mart.v_field_production AS
SELECT
    *
FROM
    oil_mart.agg_field_day;
