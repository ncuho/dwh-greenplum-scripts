SELECT
    json_build_object('check', 'relation:12:ods.og_task', 'scope', 'source_relation_finding', 'errors', (
            SELECT
                count(*)
            FROM ods.og_task s
            WHERE
                s."task_project_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_project t
                    WHERE
                        s."task_project_id" = t."id")));

