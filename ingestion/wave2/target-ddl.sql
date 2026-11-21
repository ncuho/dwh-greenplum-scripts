-- PLAN ONLY: not applied. Create only after review, before target backfill/cutover.
-- A separate raw table prevents this second-wave ingestion from silently
-- changing the already reconciled first-wave raw table.
CREATE TABLE dlh.oil_stg.event_log_wave2 (
  topic VARCHAR,
  kafka_partition INTEGER,
  kafka_offset BIGINT,
  batch_id BIGINT,
  received_at TIMESTAMP(6) WITH TIME ZONE,
  event_json VARCHAR
) WITH (format = 'PARQUET');
