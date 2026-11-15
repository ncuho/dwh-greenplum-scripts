CREATE TABLE stg.repair_event (
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

COMMENT ON TABLE stg.repair_event IS 'One incoming repair operation envelope; synthetic demonstration, not production certification';
