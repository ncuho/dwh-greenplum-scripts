-- Контекст миграции: AS IS / TO BE.
-- Назначение: Определяет справочник причин простоя для размерной модели.
-- AS IS: oil_mart.dim_downtime_reason; таблица или view исходного слоя GP.
-- TO BE: Дополнительная ветка простоев; её модели и отдельный отчёт переносятся следующей волной.
-- Отличие: Общие измерения добычи используются обеими ветками; первая волна не публикует эту витрину.
-- Конец контекста миграции.
CREATE TABLE oil_mart.dim_downtime_reason (
    reason text NOT NULL,
    description text NOT NULL)
DISTRIBUTED BY (reason);
