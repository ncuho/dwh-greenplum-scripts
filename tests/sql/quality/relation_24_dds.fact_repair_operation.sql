SELECT
    json_build_object('check', 'relation:24:dds.fact_repair_operation', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_repair_operation s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

