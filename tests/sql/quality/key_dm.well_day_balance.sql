SELECT
    json_build_object('check', 'key:dm.well_day_balance', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "business_date"
                FROM dm.well_day_balance GROUP BY "well_id", "business_date"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "business_date" IS NULL) d));

