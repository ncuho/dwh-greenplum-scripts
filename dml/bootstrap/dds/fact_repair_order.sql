INSERT INTO dds.fact_repair_order
SELECT
    w.id * 10 + q.n,
    w.id,
    w.id * 10 + 1,
    1 + (w.id % 20),
    1 + (w.id % 6),
    timestamp '2025-01-10' + (q.n - 1) * interval '3 months',
    timestamp '2025-01-10' + (q.n - 1) * interval '3 months' + CASE WHEN w.id % 10 = 0 THEN
        interval '24 hours'
    ELSE
        interval '12 hours'
    END,
    'done'::ref.work_state,
    NULL::bigint,
    1
FROM
    ods.og_tbl_well w
    CROSS JOIN generate_series(1, 4) q (n);

