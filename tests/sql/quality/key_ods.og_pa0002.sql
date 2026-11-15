SELECT
    json_build_object('check', 'key:ods.og_pa0002', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "pernr"
                FROM ods.og_pa0002 GROUP BY "pernr"
            HAVING
                count(*) <> 1
            OR "pernr" IS NULL) d));

