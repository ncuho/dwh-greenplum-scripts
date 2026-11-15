SELECT
    json_build_object('check', 'key:mart.og_report', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "id"
                FROM mart.og_report GROUP BY "id"
            HAVING
                count(*) <> 1
            OR "id" IS NULL) d));

