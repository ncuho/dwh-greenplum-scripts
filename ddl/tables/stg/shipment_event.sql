CREATE TABLE stg.shipment_event (
    "ingest_id" bigint NOT NULL,
    "source_event_key" text,
    "locality_id" bigint,
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

COMMENT ON TABLE stg.shipment_event IS 'One custody transfer envelope; synthetic demonstration, not production certification';
