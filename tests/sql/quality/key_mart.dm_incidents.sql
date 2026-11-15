SELECT
    json_build_object('check', 'key:mart.dm_incidents', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "id"
                FROM mart.dm_incidents GROUP BY "id"
            HAVING
                count(*) <> 1
            OR "id" IS NULL) d));

