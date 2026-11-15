SELECT
    json_build_object('check', 'key:ods.og_ws_user', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "ws_user_id"
                FROM ods.og_ws_user GROUP BY "ws_user_id"
            HAVING
                count(*) <> 1
            OR "ws_user_id" IS NULL) d));

