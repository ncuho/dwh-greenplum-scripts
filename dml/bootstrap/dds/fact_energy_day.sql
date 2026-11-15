INSERT INTO dds.fact_energy_day
SELECT
    p.well_id,
    p.business_date,
    t.tariff_id,
    round(p.operating_hours * s.nominal_load_kw * (1 + (p.well_id % 7)::numeric / 100), 6),
    round(p.operating_hours * s.nominal_load_kw * (1 + (p.well_id % 7)::numeric / 100) * t.rub_per_kwh, 2),
    1
FROM
    dds.fact_production_day p
    JOIN dds.dim_well_scd2 s ON s.well_id = p.well_id
        AND s.well_sk = p.well_sk
    JOIN ref.energy_tariff t ON p.business_date >= t.valid_from
        AND p.business_date < t.valid_to;

