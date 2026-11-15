SELECT
    json_build_object('check', 'key:ref.product', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "product_id"
                FROM ref.product GROUP BY "product_id"
            HAVING
                count(*) <> 1
            OR "product_id" IS NULL) d));

