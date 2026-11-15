SELECT
    well_id,
    month_start,
    repair_count,
    labor_hours,
    labor_cost_rub,
    material_cost_rub,
    run_id
FROM dm.repair_cost_month
ORDER BY well_id, month_start;
