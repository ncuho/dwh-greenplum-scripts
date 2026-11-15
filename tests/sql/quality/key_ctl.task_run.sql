SELECT
    json_build_object('check', 'key:ctl.task_run', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "run_id"
                FROM ctl.task_run GROUP BY "run_id"
            HAVING
                count(*) <> 1
            OR "run_id" IS NULL) d));

