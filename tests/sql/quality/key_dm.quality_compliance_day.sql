SELECT
    json_build_object('check', 'key:dm.quality_compliance_day', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "locality_id", "sample_date", "analyte"
                FROM dm.quality_compliance_day GROUP BY "locality_id", "sample_date", "analyte"
            HAVING
                count(*) <> 1
            OR "locality_id" IS NULL
            OR "sample_date" IS NULL
            OR "analyte" IS NULL) d));

