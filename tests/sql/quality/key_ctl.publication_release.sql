SELECT
    json_build_object('check', 'key:ctl.publication_release', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "release_id"
                FROM ctl.publication_release GROUP BY "release_id"
            HAVING
                count(*) <> 1
            OR "release_id" IS NULL) d));

