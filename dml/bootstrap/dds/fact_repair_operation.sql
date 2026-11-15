INSERT INTO dds.fact_repair_operation
SELECT
    r.repair_order_id * 10 + n,
    r.repair_order_id,
    r.well_id,
    CASE n
    WHEN 1 THEN
        'inspect'
    WHEN 2 THEN
        'replace'
    ELSE
        'test'
    END,
    (n + 1)::numeric(12, 3),
    n * 1000 + (r.well_id % 10) * 100,
    round((n + 1) * c.hour_rate_rub, 2),
    1
FROM
    dds.fact_repair_order r
    JOIN dds.dim_contract c ON c.contract_id = r.contract_id
    CROSS JOIN generate_series(1, 3) n;

