SELECT
    json_build_object('check', 'relation:38:dds.fact_shipment_item', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_shipment_item s
            WHERE
                s."locality_id" IS NOT NULL
                AND s."shipment_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM dds.fact_shipment t
                    WHERE
                        s."locality_id" = t."locality_id"
                        AND s."shipment_id" = t."shipment_id")));

