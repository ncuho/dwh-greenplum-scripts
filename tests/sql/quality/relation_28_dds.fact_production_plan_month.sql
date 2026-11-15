SELECT
    json_build_object('check', 'relation:28:dds.fact_production_plan_month', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_production_plan_month s
            WHERE
                s."well_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_well t
                    WHERE
                        s."well_id" = t."id")));

