SELECT
    json_build_object('check', 'raw_telemetry_count', 'scope', 'new_contract', 'errors', (
            SELECT
                abs((
                    SELECT
                        count(*)
                FROM stg.measurement_event) - (
            SELECT
                count(*)
            FROM dds.fact_telemetry_hour))));

