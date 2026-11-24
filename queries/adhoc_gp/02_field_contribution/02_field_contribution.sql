-- Показывает долю месторождения в годовой добыче и продуктивность активного скважино-дня.
SELECT field_name, region, sum(oil_tonnes) AS oil_tonnes,
       sum(producing_well_days) AS producing_well_days,
       round(sum(oil_tonnes) / nullif(sum(producing_well_days), 0), 3) AS tonnes_per_well_day,
       round(100.0 * sum(oil_tonnes) / nullif(sum(sum(oil_tonnes)) OVER (), 0), 2) AS contribution_pct
FROM oil_mart.v_field_production
WHERE production_date >= DATE '2025-01-01' AND production_date < DATE '2026-01-01'
GROUP BY field_name, region ORDER BY oil_tonnes DESC;
