SELECT
    json_build_object('check', 'relation:18:dds.dim_well_scd2', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.dim_well_scd2 s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

