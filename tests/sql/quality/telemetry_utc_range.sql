SELECT
    json_build_object('check', 'telemetry_utc_range', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_telemetry_hour
            WHERE
                event_ts < TIMESTAMP '2025-01-01'
                OR event_ts >= TIMESTAMP '2026-01-01'));

