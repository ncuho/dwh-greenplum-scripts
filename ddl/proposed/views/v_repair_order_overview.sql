-- Depends on dm.v_repair_cost_by_well; deploy that view first.
CREATE VIEW dm.v_repair_order_overview AS
SELECT
    repair.well_id,
    repair.repair_order_id,
    repair.opened_at,
    repair.closed_at,
    repair.status,
    cost.operation_count,
    cost.labor_hours,
    cost.material_cost_rub,
    cost.labor_cost_rub
FROM dds.fact_repair_order AS repair
LEFT JOIN dm.v_repair_cost_by_well AS cost
    ON cost.well_id = repair.well_id
    AND cost.repair_order_id = repair.repair_order_id;
