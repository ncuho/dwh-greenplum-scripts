-- Prepared definition: one well and repair order; not deployed.
CREATE VIEW dm.v_repair_cost_by_well AS
SELECT
    well_id,
    repair_order_id,
    count(*) AS operation_count,
    sum(labor_hours) AS labor_hours,
    sum(material_cost_rub) AS material_cost_rub,
    sum(labor_cost_rub) AS labor_cost_rub
FROM dds.fact_repair_operation
GROUP BY well_id, repair_order_id;
