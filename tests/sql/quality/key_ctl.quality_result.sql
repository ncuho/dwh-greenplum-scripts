SELECT
    json_build_object('check', 'key:ctl.quality_result', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "result_id"
                FROM ctl.quality_result GROUP BY "result_id"
            HAVING
                count(*) <> 1
            OR "result_id" IS NULL) d));

