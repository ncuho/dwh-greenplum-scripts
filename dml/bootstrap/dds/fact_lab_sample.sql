INSERT INTO dds.fact_lab_sample
SELECT
    p.well_id * 100 + extract(month FROM p.prod_date)::bigint,
    p.well_id,
    date_trunc('month', p.prod_date) + interval '15 days',
    1,
    'LAB-SYNTHETIC',
    1
FROM
    ods.og_tbl_production_volume p;

