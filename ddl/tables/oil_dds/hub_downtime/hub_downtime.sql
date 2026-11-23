-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит устойчивый бизнес-ключ и hash key сущности downtime; атрибуты вынесены в satellites.
-- AS IS: oil_dds.hub_downtime; таблица или view исходного слоя GP.
-- TO BE: Дополнительная ветка простоев; её модели и отдельный отчёт переносятся следующей волной.
-- Отличие: Общие измерения добычи используются обеими ветками; первая волна не публикует эту витрину.
-- Конец контекста миграции.
CREATE TABLE oil_dds.hub_downtime (
    downtime_hk text NOT NULL,
    downtime_id text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (downtime_hk);
