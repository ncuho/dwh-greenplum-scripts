SELECT
    json_build_object('check', 'relation:31:dm.energy_intensity_day', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dm.energy_intensity_day s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

