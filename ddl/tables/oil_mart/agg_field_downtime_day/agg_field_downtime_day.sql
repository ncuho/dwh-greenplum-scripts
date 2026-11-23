-- Контекст миграции: AS IS / TO BE.
-- Назначение: Агрегирует часы и причины простоев по месторождению и дате.
-- AS IS: oil_mart.agg_field_downtime_day; таблица или view исходного слоя GP.
-- TO BE: Дополнительная ветка простоев; её модели и отдельный отчёт переносятся следующей волной.
-- Отличие: Общие измерения добычи используются обеими ветками; первая волна не публикует эту витрину.
-- Конец контекста миграции.
CREATE TABLE oil_mart.agg_field_downtime_day (
    production_date date NOT NULL,
    field_hk text NOT NULL,
    downtime_hours numeric(20, 6) NOT NULL)
DISTRIBUTED BY (field_hk);
