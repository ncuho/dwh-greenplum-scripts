SELECT
    json_build_object('check', 'key:dds.fact_quality_measurement', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "sample_id", "analyte"
                FROM dds.fact_quality_measurement GROUP BY "well_id", "sample_id", "analyte"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "sample_id" IS NULL
            OR "analyte" IS NULL) d));

