SELECT
    json_build_object('check', 'key:dm.repair_cost_month', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "month_start"
                FROM dm.repair_cost_month GROUP BY "well_id", "month_start"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "month_start" IS NULL) d));

