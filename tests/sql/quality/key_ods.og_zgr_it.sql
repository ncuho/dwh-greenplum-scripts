SELECT
    json_build_object('check', 'key:ods.og_zgr_it', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "kod_gr"
                FROM ods.og_zgr_it GROUP BY "kod_gr"
            HAVING
                count(*) <> 1
            OR "kod_gr" IS NULL) d));

