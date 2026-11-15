SELECT
    json_build_object('check', 'relation:32:dm.service_production_impact', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dm.service_production_impact s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

