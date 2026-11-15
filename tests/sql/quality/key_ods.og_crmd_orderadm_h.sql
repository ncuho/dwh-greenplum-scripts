SELECT
    json_build_object('check', 'key:ods.og_crmd_orderadm_h', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "object_id"
                FROM ods.og_crmd_orderadm_h GROUP BY "object_id"
            HAVING
                count(*) <> 1
            OR "object_id" IS NULL) d));

