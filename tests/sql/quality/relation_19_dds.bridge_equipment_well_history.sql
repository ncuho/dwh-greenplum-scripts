SELECT
    json_build_object('check', 'relation:19:dds.bridge_equipment_well_history', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.bridge_equipment_well_history s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

