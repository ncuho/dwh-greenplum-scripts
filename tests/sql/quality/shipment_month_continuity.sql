SELECT
    json_build_object('check', 'shipment_month_continuity', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    *, lag(closing_m3) OVER (PARTITION BY locality_id, product_id ORDER BY month_start) prev FROM dm.shipment_balance_month) d
            WHERE
                prev IS NOT NULL
                AND prev <> opening_m3));

