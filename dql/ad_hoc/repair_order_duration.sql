SELECT
    repair.well_id,
    repair.repair_order_id,
    repair.opened_at,
    repair.closed_at,
    CASE
        WHEN repair.closed_at IS NOT NULL AND repair.opened_at IS NOT NULL
        THEN extract(epoch FROM (repair.closed_at - repair.opened_at)) / 3600.0
        ELSE NULL
    END AS elapsed_hours
FROM dds.fact_repair_order AS repair
ORDER BY repair.well_id, repair.repair_order_id;
