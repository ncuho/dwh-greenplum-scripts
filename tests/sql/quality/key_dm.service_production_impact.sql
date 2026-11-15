SELECT
    json_build_object('check', 'key:dm.service_production_impact', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "servicecall_id", "well_id"
                FROM dm.service_production_impact GROUP BY "servicecall_id", "well_id"
            HAVING
                count(*) <> 1
            OR "servicecall_id" IS NULL
            OR "well_id" IS NULL) d));

