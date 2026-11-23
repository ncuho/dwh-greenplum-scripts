-- Создаёт таблицу oil_dds.sat_field.
CREATE TABLE oil_dds.sat_field (
    field_hk text NOT NULL,
    event_id text NOT NULL,
    entity_version bigint NOT NULL,
    op text NOT NULL,
    event_time timestamptz NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    hashdiff text NOT NULL,
    field_name text,
    region text)
DISTRIBUTED BY (field_hk);
