-- Назначение: Связывает исходные партии с объединённой партией и сохраняет число исходных доставок.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_stg.batch_coalesce_map (
    original_batch_id bigint PRIMARY KEY,
    coalesced_batch_id bigint NOT NULL,
    source_name text NOT NULL,
    original_event_count bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now())
DISTRIBUTED BY (original_batch_id);
