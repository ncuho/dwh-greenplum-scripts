SELECT
    locality_id,
    month_start,
    oil_actual_legacy,
    oil_plan_legacy,
    plan_attainment_pct,
    energy_cost_rub,
    downtime_hours,
    run_id
FROM dm.field_month_performance
ORDER BY locality_id, month_start;
