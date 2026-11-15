CREATE TABLE dds.fact_telemetry_hour (
    "well_id" bigint NOT NULL,
    "event_ts" timestamp NOT NULL,
    "well_sk" bigint,
    "pressure_kpa" numeric(12, 3),
    "temperature_c" numeric(8, 3),
    "vibration_mm_s" numeric(8, 4),
    "water_cut_pct" numeric(7, 3),
    "quality_flag" text,
    "batch_id" bigint
)
WITH (
    appendonly = true,
    orientation = column,
    compresstype = zlib,
    compresslevel = 3
)
DISTRIBUTED BY (well_id)
PARTITION BY RANGE (event_ts) (
    START (TIMESTAMP '2025-01-01')
    END (TIMESTAMP '2026-01-01')
    EVERY (INTERVAL '1 month'),
    DEFAULT PARTITION outside_period
);

COMMENT ON TABLE dds.fact_telemetry_hour IS 'One well/hour; four physical synthetic sensors; synthetic demonstration, not production certification';
