SELECT
    json_build_object('check', 'relation:5:ods.og_tbl_workrecord', 'scope', 'source_relation_finding', 'errors', (
            SELECT
                count(*)
            FROM ods.og_tbl_workrecord s
            WHERE
                s."employee" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_employee t
                    WHERE
                        s."employee" = t."id")));

