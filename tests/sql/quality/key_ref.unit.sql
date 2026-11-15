SELECT
    json_build_object('check', 'key:ref.unit', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "unit_code"
                FROM ref.unit GROUP BY "unit_code"
            HAVING
                count(*) <> 1
            OR "unit_code" IS NULL) d));

