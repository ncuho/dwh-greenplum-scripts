SELECT
    json_build_object('check', 'key:dm.energy_intensity_day', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "business_date"
                FROM dm.energy_intensity_day GROUP BY "well_id", "business_date"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "business_date" IS NULL) d));

