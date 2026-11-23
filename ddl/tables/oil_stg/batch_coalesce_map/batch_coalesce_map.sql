-- Создаёт таблицу oil_stg.batch_coalesce_map.
CREATE TABLE oil_stg.batch_coalesce_map (
    original_batch_id bigint PRIMARY KEY,
    coalesced_batch_id bigint NOT NULL,
    source_name text NOT NULL,
    original_event_count bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now())
DISTRIBUTED BY (original_batch_id);
