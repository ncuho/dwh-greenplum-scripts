SELECT
    json_build_object('check', 'key:stg.lab_event', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "ingest_id"
                FROM stg.lab_event GROUP BY "ingest_id"
            HAVING
                count(*) <> 1
            OR "ingest_id" IS NULL) d));

