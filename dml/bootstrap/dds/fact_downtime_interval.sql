INSERT INTO dds.fact_downtime_interval
SELECT
    repair_order_id,
    well_id,
    opened_at,
    closed_at,
    CASE WHEN well_id % 3 = 0 THEN
        2
    ELSE
        1
    END,
    repair_order_id,
    well_id % 3 <> 0,
    1
FROM
    dds.fact_repair_order;

