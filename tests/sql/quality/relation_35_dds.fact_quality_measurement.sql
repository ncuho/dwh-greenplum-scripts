SELECT
    json_build_object('check', 'relation:35:dds.fact_quality_measurement', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_quality_measurement s
            WHERE
                s."well_id" IS NOT NULL
                AND s."sample_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM dds.fact_lab_sample t
                    WHERE
                        s."well_id" = t."well_id"
                        AND s."sample_id" = t."sample_id")));

