SELECT
    json_build_object('check', 'relation:26:dds.fact_lab_sample', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_lab_sample s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

