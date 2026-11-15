SELECT
    json_build_object('check', 'key:mart.bo_werks_text', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "zkz_werks"
                FROM mart.bo_werks_text GROUP BY "zkz_werks"
            HAVING
                count(*) <> 1
            OR "zkz_werks" IS NULL) d));

