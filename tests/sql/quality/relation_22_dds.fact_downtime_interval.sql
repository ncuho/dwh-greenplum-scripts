SELECT
    json_build_object('check', 'relation:22:dds.fact_downtime_interval', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_downtime_interval s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

