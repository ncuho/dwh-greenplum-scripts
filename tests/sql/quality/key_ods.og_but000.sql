SELECT
    json_build_object('check', 'key:ods.og_but000', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "partner"
                FROM ods.og_but000 GROUP BY "partner"
            HAVING
                count(*) <> 1
            OR "partner" IS NULL) d));

