SELECT
    json_build_object('check', 'key:mart.og_bs_area', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "bs_area"
                FROM mart.og_bs_area GROUP BY "bs_area"
            HAVING
                count(*) <> 1
            OR "bs_area" IS NULL) d));

