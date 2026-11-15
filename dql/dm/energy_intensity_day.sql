SELECT
    well_id,
    business_date,
    energy_kwh,
    oil_legacy_quantity,
    kwh_per_legacy_unit,
    run_id
FROM dm.energy_intensity_day
ORDER BY well_id, business_date;
