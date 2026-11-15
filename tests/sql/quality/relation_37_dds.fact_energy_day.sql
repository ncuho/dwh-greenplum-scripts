SELECT
    json_build_object('check', 'relation:37:dds.fact_energy_day', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_energy_day s
            WHERE
                s."tariff_id" IS NOT NULL
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM ref.energy_tariff t
                    WHERE
                        s."tariff_id" = t."tariff_id")));

