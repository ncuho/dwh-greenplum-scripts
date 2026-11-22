CREATE TABLE oil_dds.link_downtime_well (
    link_hk text NOT NULL,
    downtime_hk text NOT NULL,
    well_hk text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (downtime_hk);
