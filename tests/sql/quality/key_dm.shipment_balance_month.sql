SELECT
    json_build_object('check', 'key:dm.shipment_balance_month', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "locality_id", "month_start", "product_id"
                FROM dm.shipment_balance_month GROUP BY "locality_id", "month_start", "product_id"
            HAVING
                count(*) <> 1
            OR "locality_id" IS NULL
            OR "month_start" IS NULL
            OR "product_id" IS NULL) d));

