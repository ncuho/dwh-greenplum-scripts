SELECT
    json_build_object('check', 'key:dds.fact_shipment_item', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "locality_id", "shipment_id", "line_no"
                FROM dds.fact_shipment_item GROUP BY "locality_id", "shipment_id", "line_no"
            HAVING
                count(*) <> 1
            OR "locality_id" IS NULL
            OR "shipment_id" IS NULL
            OR "line_no" IS NULL) d));

