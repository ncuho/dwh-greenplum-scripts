SELECT
    json_build_object('check', 'key:ref.energy_tariff', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "tariff_id"
                FROM ref.energy_tariff GROUP BY "tariff_id"
            HAVING
                count(*) <> 1
            OR "tariff_id" IS NULL) d));

