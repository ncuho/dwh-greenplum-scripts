SELECT
    json_build_object('check', 'relation:29:dm.well_day_balance', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dm.well_day_balance s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

