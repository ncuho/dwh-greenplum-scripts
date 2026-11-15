SELECT
    json_build_object('check', 'relation:33:dds.fact_production_day', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_production_day s
            WHERE
                s."source_month_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_production_volume t
                    WHERE
                        s."source_month_id" = t."id")));

