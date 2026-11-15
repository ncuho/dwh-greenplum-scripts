SELECT
    json_build_object('check', 'key:dds.fact_repair_order', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "repair_order_id"
                FROM dds.fact_repair_order GROUP BY "well_id", "repair_order_id"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "repair_order_id" IS NULL) d));

