CREATE VIEW dm.v_production_dashboard AS
SELECT
    m.locality_id,
    l.name AS locality_name,
    m.month_start,
    m.oil_actual_legacy,
    m.oil_plan_legacy,
    m.plan_attainment_pct,
    m.energy_cost_rub,
    m.downtime_hours
FROM
    dm.field_month_performance m
    JOIN ods.og_tbl_locality l ON l.id = m.locality_id;

