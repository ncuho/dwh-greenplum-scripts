SELECT
    json_build_object('check', 'key:ref.quality_spec', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "spec_id"
                FROM ref.quality_spec GROUP BY "spec_id"
            HAVING
                count(*) <> 1
            OR "spec_id" IS NULL) d));

