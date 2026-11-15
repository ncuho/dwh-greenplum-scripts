SELECT
    json_build_object('check', 'key:mart.dm_well_production', 'scope', 'mirror_key', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "id"
                FROM mart.dm_well_production GROUP BY "id"
            HAVING
                count(*) <> 1
            OR "id" IS NULL) d));

