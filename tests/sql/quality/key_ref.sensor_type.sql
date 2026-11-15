SELECT
    json_build_object('check', 'key:ref.sensor_type', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "sensor_type_id"
                FROM ref.sensor_type GROUP BY "sensor_type_id"
            HAVING
                count(*) <> 1
            OR "sensor_type_id" IS NULL) d));

