SELECT
    json_build_object('check', 'key:ref.downtime_reason', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "reason_id"
                FROM ref.downtime_reason GROUP BY "reason_id"
            HAVING
                count(*) <> 1
            OR "reason_id" IS NULL) d));

