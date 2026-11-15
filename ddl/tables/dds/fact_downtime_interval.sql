CREATE TABLE dds.fact_downtime_interval (
    "downtime_id" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "starts_at" timestamp,
    "ends_at" timestamp,
    "reason_id" integer,
    "repair_order_id" bigint,
    "planned" boolean,
    "batch_id" bigint,
    PRIMARY KEY ("well_id","downtime_id")
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_downtime_interval IS 'One non-overlapping well downtime interval; synthetic demonstration, not production certification';
