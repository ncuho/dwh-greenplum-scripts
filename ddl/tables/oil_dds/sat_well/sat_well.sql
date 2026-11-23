-- Создаёт таблицу oil_dds.sat_well.
CREATE TABLE oil_dds.sat_well (
    well_hk text NOT NULL,
    link_hk text NOT NULL,
    event_id text NOT NULL,
    entity_version bigint NOT NULL,
    op text NOT NULL,
    event_time timestamptz NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    hashdiff text NOT NULL,
    well_name text,
    valid_from date,
    status text)
DISTRIBUTED BY (well_hk);
