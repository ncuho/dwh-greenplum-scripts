SELECT
    json_build_object('check', 'key:dm.field_month_performance', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "locality_id", "month_start"
                FROM dm.field_month_performance GROUP BY "locality_id", "month_start"
            HAVING
                count(*) <> 1
            OR "locality_id" IS NULL
            OR "month_start" IS NULL) d));

