-- Создаёт таблицу oil_dds.sat_daily_production.
CREATE TABLE oil_dds.sat_daily_production (
    production_hk text NOT NULL,
    link_hk text NOT NULL,
    event_id text NOT NULL,
    entity_version bigint NOT NULL,
    op text NOT NULL,
    event_time timestamptz NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    hashdiff text NOT NULL,
    production_date date,
    oil_tonnes numeric(18, 3),
    status text)
DISTRIBUTED BY (production_hk);
