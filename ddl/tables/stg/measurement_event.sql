CREATE TABLE stg.measurement_event (
    "ingest_id" bigint NOT NULL,
    "source_event_key" text,
    "well_id" bigint,
    "event_ts" timestamp,
    "payload" json,
    "batch_id" bigint
)
WITH (
    appendonly = true,
    orientation = row,
    compresstype = zlib,
    compresslevel = 3
)
DISTRIBUTED RANDOMLY;

COMMENT ON TABLE stg.measurement_event IS 'One received hourly observation envelope; synthetic demonstration, not production certification';
