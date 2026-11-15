SELECT
    json_build_object('check', 'key:ods.og_asu_work_assignment', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "assigment_id"
                FROM ods.og_asu_work_assignment GROUP BY "assigment_id"
            HAVING
                count(*) <> 1
            OR "assigment_id" IS NULL) d));

