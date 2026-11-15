INSERT INTO dds.bridge_equipment_well_history
SELECT
    w.id,
    w.id * 10 + e.n,
    date '2025-01-01',
    date '2026-01-01'
FROM
    ods.og_tbl_well w
    CROSS JOIN (
        VALUES (1),
            (2)) e (n);

