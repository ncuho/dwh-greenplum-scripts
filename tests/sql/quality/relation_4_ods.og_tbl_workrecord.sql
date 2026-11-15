SELECT
    json_build_object('check', 'relation:4:ods.og_tbl_workrecord', 'scope', 'source_relation_finding', 'errors', (
            SELECT
                count(*)
            FROM ods.og_tbl_workrecord s
            WHERE
                s."servicecall" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_servicecall t
                    WHERE
                        s."servicecall" = t."id")));

