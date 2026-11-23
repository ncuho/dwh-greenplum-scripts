-- Создаёт таблицу oil_dds.sat_downtime.
CREATE TABLE oil_dds.sat_downtime (
    downtime_hk text NOT NULL,
    link_hk text NOT NULL,
    event_id text NOT NULL,
    entity_version bigint NOT NULL,
    op text NOT NULL,
    event_time timestamptz NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    hashdiff text NOT NULL,
    start_at timestamptz,
    end_at timestamptz,
    reason text)
DISTRIBUTED BY (downtime_hk);
