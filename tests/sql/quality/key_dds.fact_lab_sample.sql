SELECT
    json_build_object('check', 'key:dds.fact_lab_sample', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "sample_id"
                FROM dds.fact_lab_sample GROUP BY "well_id", "sample_id"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "sample_id" IS NULL) d));

