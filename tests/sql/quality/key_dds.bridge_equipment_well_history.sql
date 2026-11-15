SELECT
    json_build_object('check', 'key:dds.bridge_equipment_well_history', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "equipment_id", "valid_from"
                FROM dds.bridge_equipment_well_history GROUP BY "well_id", "equipment_id", "valid_from"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "equipment_id" IS NULL
            OR "valid_from" IS NULL) d));

