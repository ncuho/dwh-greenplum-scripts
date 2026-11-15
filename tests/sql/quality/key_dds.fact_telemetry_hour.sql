SELECT
    json_build_object('check', 'key:dds.fact_telemetry_hour', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "event_ts"
                FROM dds.fact_telemetry_hour GROUP BY "well_id", "event_ts"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "event_ts" IS NULL) d));

