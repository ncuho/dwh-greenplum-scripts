SELECT
    json_build_object('check', 'relation:34:dds.fact_repair_operation', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_repair_operation s
            WHERE
                s."well_id" IS NOT NULL
                AND s."repair_order_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM dds.fact_repair_order t
                    WHERE
                        s."well_id" = t."well_id"
                        AND s."repair_order_id" = t."repair_order_id")));

