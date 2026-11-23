-- Контекст миграции: AS IS / TO BE.
-- Назначение: Учитывает состояния исходных партий и завершённость применения.
-- AS IS: oil_stg.batch_control; таблица или view исходного слоя GP.
-- TO BE: Логический аналог в Iceberg release; текущий код первой волны — pipelines/production_online в DLH.
-- Отличие: GP distribution/индексы не копируются; бизнес-ключи, типы и смысл связей сохраняются и проверяются DQ.
-- Конец контекста миграции.
CREATE TABLE oil_stg.batch_control (
    batch_id bigint PRIMARY KEY,
    source_name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    status text NOT NULL CHECK (status IN ('OPEN', 'READY', 'COALESCED', 'APPLIED', 'FAILED')),
    source_manifest text,
    error_text text)
DISTRIBUTED BY (batch_id);
