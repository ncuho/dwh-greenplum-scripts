SELECT
    json_build_object('check', 'telemetry_expected_count', 'scope', 'new_contract', 'errors', (
            SELECT
                abs(count(*) - (
                    SELECT
                        count(*)
                    FROM dds.fact_production_day) * 24)
            FROM dds.fact_telemetry_hour));

