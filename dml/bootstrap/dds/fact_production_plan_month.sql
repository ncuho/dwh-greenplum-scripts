INSERT INTO dds.fact_production_plan_month
SELECT
    p.well_id,
    date_trunc('month', p.prod_date)::date,
    s.scenario,
    round(p.oil_volume::numeric * (
            CASE WHEN s.scenario = 'base' THEN
                1.05
            ELSE
                1.10
            END), 6),
    round(p.gas_volume::numeric * (
            CASE WHEN s.scenario = 'base' THEN
                1.03
            ELSE
                1.07
            END), 6),
    (c.days_in_month * 24 * (40 + p.well_id % 20 * 2))::numeric(20, 6),
    1
FROM
    ods.og_tbl_production_volume p
    JOIN ref.calendar c ON c.business_date = date_trunc('month', p.prod_date)::date
    CROSS JOIN (
        VALUES ('base'),
            ('stretch')) s (scenario);

