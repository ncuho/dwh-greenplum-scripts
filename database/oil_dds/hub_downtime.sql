CREATE TABLE oil_dds.hub_downtime (
    downtime_hk text NOT NULL,
    downtime_id text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (downtime_hk);
