SELECT
    json_build_object('check', 'key:dds.fact_shipment', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "locality_id", "shipment_id"
                FROM dds.fact_shipment GROUP BY "locality_id", "shipment_id"
            HAVING
                count(*) <> 1
            OR "locality_id" IS NULL
            OR "shipment_id" IS NULL) d));

