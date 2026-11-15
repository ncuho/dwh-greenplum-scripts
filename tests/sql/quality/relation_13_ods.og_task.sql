SELECT
    json_build_object('check', 'relation:13:ods.og_task', 'scope', 'source_relation_finding', 'errors', (
            SELECT
                count(*)
            FROM ods.og_task s
            WHERE
                s."assigned_ws_user_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ods.og_ws_user t
                    WHERE
                        s."assigned_ws_user_id" = t."ws_user_id")));

