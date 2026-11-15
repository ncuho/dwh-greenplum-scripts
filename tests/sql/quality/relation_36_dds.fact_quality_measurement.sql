SELECT
    json_build_object('check', 'relation:36:dds.fact_quality_measurement', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_quality_measurement s
            WHERE
                s."spec_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ref.quality_spec t
                    WHERE
                        s."spec_id" = t."spec_id")));

