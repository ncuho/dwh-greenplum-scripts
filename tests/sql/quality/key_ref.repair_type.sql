SELECT
    json_build_object('check', 'key:ref.repair_type', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "repair_type_id"
                FROM ref.repair_type GROUP BY "repair_type_id"
            HAVING
                count(*) <> 1
            OR "repair_type_id" IS NULL) d));

