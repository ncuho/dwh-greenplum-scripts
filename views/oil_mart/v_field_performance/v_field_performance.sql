-- Контекст миграции: AS IS / TO BE.
-- Назначение: Объединяет добычу и простои для отчёта эффективности.
-- AS IS: oil_mart.v_field_performance; таблица или view исходного слоя GP.
-- TO BE: Дополнительная ветка простоев; её модели и отдельный отчёт переносятся следующей волной.
-- Отличие: Общие измерения добычи используются обеими ветками; первая волна не публикует эту витрину.
-- Конец контекста миграции.
CREATE VIEW oil_mart.v_field_performance AS
SELECT
    p.*,
    CAST(coalesce(d.downtime_hours, 0) AS numeric(20, 6)) AS downtime_hours
FROM
    oil_mart.agg_field_day p
    LEFT JOIN oil_mart.agg_field_downtime_day d ON d.production_date = p.production_date
        AND d.field_hk = p.field_hk;
