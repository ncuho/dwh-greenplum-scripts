-- Контекст миграции: AS IS / TO BE.
-- Назначение: Хранит историю связи downtime_well через hash keys связанных hubs.
-- AS IS: oil_dds.link_downtime_well; таблица или view исходного слоя GP.
-- TO BE: Дополнительная ветка простоев; её модели и отдельный отчёт переносятся следующей волной.
-- Отличие: Общие измерения добычи используются обеими ветками; первая волна не публикует эту витрину.
-- Конец контекста миграции.
CREATE TABLE oil_dds.link_downtime_well (
    link_hk text NOT NULL,
    downtime_hk text NOT NULL,
    well_hk text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (downtime_hk);
