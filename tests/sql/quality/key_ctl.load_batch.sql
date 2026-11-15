SELECT
    json_build_object('check', 'key:ctl.load_batch', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "batch_id"
                FROM ctl.load_batch GROUP BY "batch_id"
            HAVING
                count(*) <> 1
            OR "batch_id" IS NULL) d));

