SELECT
    json_build_object('check', 'key:dds.fact_production_day', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "business_date"
                FROM dds.fact_production_day GROUP BY "well_id", "business_date"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "business_date" IS NULL) d));

