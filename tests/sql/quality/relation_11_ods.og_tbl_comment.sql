SELECT
    json_build_object('check', 'relation:11:ods.og_tbl_comment', 'scope', 'source_relation_finding', 'errors', (
            SELECT
                count(*)
            FROM ods.og_tbl_comment s
            WHERE
                s."servicecall_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_servicecall t
                    WHERE
                        s."servicecall_id" = t."id")));

