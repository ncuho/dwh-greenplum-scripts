-- Создаёт таблицу oil_dds.event.
CREATE TABLE oil_dds.event (
    event_id text PRIMARY KEY,
    event_type text NOT NULL,
    entity_id text NOT NULL,
    entity_version bigint NOT NULL,
    op text NOT NULL,
    event_time timestamptz NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    batch_id bigint NOT NULL,
    payload text NOT NULL,
    event_document text NOT NULL)
DISTRIBUTED BY (event_id);
