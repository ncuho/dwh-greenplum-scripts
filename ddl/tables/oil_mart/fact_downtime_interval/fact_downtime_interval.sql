-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит интервалы простоя и их связь со скважино-днём.
-- AS IS: oil_mart.fact_downtime_interval; таблица или view исходного слоя GP.
-- TO BE: Дополнительная ветка простоев; её модели и отдельный отчёт переносятся следующей волной.
-- Отличие: Общие измерения добычи используются обеими ветками; первая волна не публикует эту витрину.
-- Конец контекста миграции.
CREATE TABLE oil_mart.fact_downtime_interval (
    downtime_hk text NOT NULL,
    well_hk text NOT NULL,
    field_hk text NOT NULL,
    start_at timestamptz NOT NULL,
    end_at timestamptz NOT NULL,
    reason text NOT NULL,
    hours numeric(16, 6) NOT NULL)
DISTRIBUTED BY (well_hk);
