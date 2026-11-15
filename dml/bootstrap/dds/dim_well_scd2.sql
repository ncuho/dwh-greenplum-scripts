INSERT INTO dds.dim_well_scd2
SELECT
    w.id * 10 + v.n,
    w.id,
    w.fieldid,
    CASE WHEN v.n = 1 THEN
        date '2025-01-01'
    ELSE
        date '2025-07-01'
    END,
    CASE WHEN v.n = 1 THEN
        date '2025-07-01'
    ELSE
        date '2026-01-01'
    END,
    CASE WHEN v.n = 1 THEN
        'baseline'
    ELSE
        'efficient'
    END,
    40 + (w.id % 20) * 2 - v.n,
    v.n = 2
FROM
    ods.og_tbl_well w
    CROSS JOIN (
        VALUES (1),
            (2)) v (n);

