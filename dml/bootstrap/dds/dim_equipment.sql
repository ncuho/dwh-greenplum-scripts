INSERT INTO dds.dim_equipment
SELECT
    w.id * 10 + e.n,
    'EQ-' || w.id || '-' || e.n,
    CASE WHEN e.n = 1 THEN
        'pump'
    ELSE
        'meter'
    END,
    date '2020-01-01' + (w.id % 365)::int,
    CASE WHEN e.n = 1 THEN
        45 + (w.id % 20) * 2
    ELSE
        1
    END
FROM
    ods.og_tbl_well w
    CROSS JOIN (
        VALUES (1),
            (2)) e (n);

