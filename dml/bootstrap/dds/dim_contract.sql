WITH companies AS (
    SELECT
        id,
        row_number() OVER (ORDER BY id) AS rn,
        count(*) OVER () AS total
    FROM
        ods.og_tbl_company)
    INSERT INTO dds.dim_contract
    SELECT
        n,
        c.id,
        date '2025-01-01',
        date '2026-01-01',
        1500 + (n % 5) * 200,
    'RUB'
FROM
    generate_series(1, 20) n
    JOIN companies c ON c.rn = (n - 1) % c.total + 1;

