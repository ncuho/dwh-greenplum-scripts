SELECT
    json_build_object('check', 'key:ods.og_crmd_activity_h', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "id"
                FROM ods.og_crmd_activity_h GROUP BY "id"
            HAVING
                count(*) <> 1
            OR "id" IS NULL) d));

