SELECT
    json_build_object('check', 'key:ods.og_tbl_changerequest', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "id"
                FROM ods.og_tbl_changerequest GROUP BY "id"
            HAVING
                count(*) <> 1
            OR "id" IS NULL) d));

