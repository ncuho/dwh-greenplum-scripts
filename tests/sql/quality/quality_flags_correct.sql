SELECT
    json_build_object('check', 'quality_flags_correct', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_quality_measurement m
            JOIN ref.quality_spec s ON s.spec_id = m.spec_id
            WHERE
                m.is_compliant IS DISTINCT FROM (m.measured_value >= s.min_value
                    AND m.measured_value <= s.max_value)));

