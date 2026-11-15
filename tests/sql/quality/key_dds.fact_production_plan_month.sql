SELECT
    json_build_object('check', 'key:dds.fact_production_plan_month', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "month_start", "scenario"
                FROM dds.fact_production_plan_month GROUP BY "well_id", "month_start", "scenario"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "month_start" IS NULL
            OR "scenario" IS NULL) d));

