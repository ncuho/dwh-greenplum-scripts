INSERT INTO dds.fact_production_day
SELECT
    f.well_id,
    f.business_date,
    s.well_sk,
    f.source_month_id,
    f.oil_floor + CASE WHEN business_date = residual_day THEN
        oil_month - sum(oil_floor) OVER (PARTITION BY f.well_id, source_month_id)
    ELSE
        0
    END,
    f.gas_floor + CASE WHEN business_date = residual_day THEN
        gas_month - sum(gas_floor) OVER (PARTITION BY f.well_id, source_month_id)
    ELSE
        0
    END,
    f.water_floor + CASE WHEN business_date = residual_day THEN
        water_month - sum(water_floor) OVER (PARTITION BY f.well_id, source_month_id)
    ELSE
        0
    END,
    operating_hours,
    'legacy_numeric_proxy_v1',
    1
FROM
    production_floors f
    JOIN dds.dim_well_scd2 s ON s.well_id = f.well_id
        AND f.business_date >= s.valid_from
        AND f.business_date < s.valid_to;

