SELECT
    json_build_object('check', 'relation:10:ods.og_tbl_servicecall', 'scope', 'source_relation_finding', 'errors', (
            SELECT
                count(*)
            FROM ods.og_tbl_servicecall s
            WHERE
                s."service_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_slmservice t
                    WHERE
                        s."service_id" = t."id")));

