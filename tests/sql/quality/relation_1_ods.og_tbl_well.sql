SELECT
    json_build_object('check', 'relation:1:ods.og_tbl_well', 'scope', 'source_relation_finding', 'errors', (
            SELECT
                count(*)
            FROM ods.og_tbl_well s
            WHERE
                s."fieldid" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_tbl_locality t
                    WHERE
                        s."fieldid" = t."id")));

