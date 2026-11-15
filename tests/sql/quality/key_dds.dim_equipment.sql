SELECT
    json_build_object('check', 'key:dds.dim_equipment', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "equipment_id"
                FROM dds.dim_equipment GROUP BY "equipment_id"
            HAVING
                count(*) <> 1
            OR "equipment_id" IS NULL) d));

