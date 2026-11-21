CREATE TABLE oil_dds.hub_well (
    well_hk text NOT NULL,
    well_id text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (well_hk);
