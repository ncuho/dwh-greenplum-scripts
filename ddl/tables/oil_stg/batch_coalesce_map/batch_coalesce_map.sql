-- Контекст миграции: AS IS / TO BE.
-- Назначение: Связывает исходные партии с объединённой партией аудита.
-- AS IS: oil_stg.batch_coalesce_map; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_stg.batch_coalesce_map (
    original_batch_id bigint PRIMARY KEY,
    coalesced_batch_id bigint NOT NULL,
    source_name text NOT NULL,
    original_event_count bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now())
DISTRIBUTED BY (original_batch_id);
