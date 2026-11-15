SELECT
    json_build_object('check', 'energy_price', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_energy_day e
            JOIN ref.energy_tariff t ON t.tariff_id = e.tariff_id
            WHERE
                e.energy_kwh < 0
                OR e.energy_cost_rub <> round(e.energy_kwh * t.rub_per_kwh, 2)));

