SELECT
    json_build_object('check', 'key:ods.og_tbl_locality', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "id"
                FROM ods.og_tbl_locality GROUP BY "id"
            HAVING
                count(*) <> 1
            OR "id" IS NULL) d));

