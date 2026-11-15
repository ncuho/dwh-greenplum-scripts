SELECT
    json_build_object('check', 'key:dds.fact_repair_operation', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "operation_id"
                FROM dds.fact_repair_operation GROUP BY "well_id", "operation_id"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "operation_id" IS NULL) d));

