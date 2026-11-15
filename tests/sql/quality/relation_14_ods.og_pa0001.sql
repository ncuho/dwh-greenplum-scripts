SELECT
    json_build_object('check', 'relation:14:ods.og_pa0001', 'scope', 'source_relation_finding', 'errors', (
            SELECT
                count(*)
            FROM ods.og_pa0001 s
            WHERE
                s."pernr" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_pa0002 t
                    WHERE
                        s."pernr" = t."pernr")));

