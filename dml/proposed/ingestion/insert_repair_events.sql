-- Prepared, not executed. This statement reads the complete external input.
-- Source-key uniqueness and input quality MUST be checked before any commit.
\set ON_ERROR_STOP on
BEGIN;
INSERT INTO stg.repair_event (
    ingest_id, source_event_key, well_id, event_ts, payload, batch_id
)
SELECT
    ingest_id, source_event_key, well_id, event_ts, payload, batch_id
FROM stg.ext_repair_event
WHERE batch_id = :'batch_id'::bigint;
ROLLBACK;
