SELECT
    json_build_object('check', 'key:ods.og_t500p', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "persa"
                FROM ods.og_t500p GROUP BY "persa"
            HAVING
                count(*) <> 1
            OR "persa" IS NULL) d));

