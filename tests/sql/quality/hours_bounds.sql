SELECT
    json_build_object('check', 'hours_bounds', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_production_day
            WHERE
                operating_hours < 0
                OR operating_hours > 24));

