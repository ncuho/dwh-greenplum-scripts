INSERT INTO dds.fact_telemetry_hour
SELECT
    p.well_id,
    p.business_date::timestamp + h.n * interval '1 hour',
    p.well_sk,
    12000 + (p.well_id % 40) * 75 + h.n * 3,
    45 + (p.well_id % 15) + h.n::numeric / 10,
    CASE WHEN p.well_id % 17 = 0
        AND extract(month FROM p.business_date) = 7 THEN
        12
    ELSE
        2 + (p.well_id % 5)::numeric / 10
    END,
    30 + (p.well_id % 50),
    CASE WHEN p.well_id % 17 = 0
        AND extract(month FROM p.business_date) = 7 THEN
        'synthetic_alert'
    ELSE
        'valid'
    END,
    1
FROM
    dds.fact_production_day p
    CROSS JOIN generate_series(0, 23) h (n);

