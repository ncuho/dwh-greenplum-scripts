SELECT
    json_build_object('check', 'key:dds.fact_downtime_interval', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "downtime_id"
                FROM dds.fact_downtime_interval GROUP BY "well_id", "downtime_id"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "downtime_id" IS NULL) d));

