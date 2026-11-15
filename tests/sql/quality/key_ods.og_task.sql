SELECT
    json_build_object('check', 'key:ods.og_task', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "task_id"
                FROM ods.og_task GROUP BY "task_id"
            HAVING
                count(*) <> 1
            OR "task_id" IS NULL) d));

