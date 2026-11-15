SELECT
    json_build_object('check', 'key:ods.og_znapr', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "kod_napr"
                FROM ods.og_znapr GROUP BY "kod_napr"
            HAVING
                count(*) <> 1
            OR "kod_napr" IS NULL) d));

