SELECT
    json_build_object('check', 'key:mart.dm_project_status', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "id"
                FROM mart.dm_project_status GROUP BY "id"
            HAVING
                count(*) <> 1
            OR "id" IS NULL) d));

