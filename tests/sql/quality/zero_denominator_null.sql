SELECT
    json_build_object('check', 'zero_denominator_null', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dm.energy_intensity_day
            WHERE (oil_legacy_quantity = 0
                AND kwh_per_legacy_unit IS NOT NULL)
            OR (oil_legacy_quantity <> 0
                AND kwh_per_legacy_unit IS NULL)));

