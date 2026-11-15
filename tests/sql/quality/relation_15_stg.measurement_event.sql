SELECT
    json_build_object('check', 'relation:15:stg.measurement_event', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM stg.measurement_event s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

