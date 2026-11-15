SELECT
    well_id,
    business_date,
    locality_id,
    oil_legacy_quantity,
    plan_oil_legacy,
    lost_quantity_proxy,
    downtime_hours,
    energy_kwh,
    energy_cost_rub,
    run_id
FROM dm.well_day_balance
ORDER BY well_id, business_date;
