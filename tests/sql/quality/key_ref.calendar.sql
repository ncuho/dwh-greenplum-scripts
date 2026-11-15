SELECT
    json_build_object('check', 'key:ref.calendar', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "business_date"
                FROM ref.calendar GROUP BY "business_date"
            HAVING
                count(*) <> 1
            OR "business_date" IS NULL) d));

