-- GP6 CREATE EXTERNAL TABLE grammar; :gpfdist_uri is a psql string variable.
-- Not installed. Set the real gpfdist URI and validate network/format before use.
\set ON_ERROR_STOP on
CREATE READABLE EXTERNAL TABLE stg.ext_repair_event (
    ingest_id bigint,
    source_event_key text,
    well_id bigint,
    event_ts timestamp,
    payload json,
    batch_id bigint
)
LOCATION (:'gpfdist_uri')
FORMAT 'CSV' (HEADER DELIMITER ',');
