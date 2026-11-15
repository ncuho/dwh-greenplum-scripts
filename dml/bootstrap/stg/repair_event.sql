INSERT INTO stg.repair_event
SELECT
    o.operation_id,
    'repair:' || o.operation_id,
    o.well_id,
    r.closed_at,
    json_build_object('order_id', o.repair_order_id, 'operation', o.operation_code, 'hours', o.labor_hours, 'cost_rub', o.material_cost_rub + o.labor_cost_rub),
    o.batch_id
FROM
    dds.fact_repair_operation o
    JOIN dds.fact_repair_order r ON r.well_id = o.well_id
        AND r.repair_order_id = o.repair_order_id;

