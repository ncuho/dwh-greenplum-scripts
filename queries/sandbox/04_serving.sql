-- Greenplum: aggregate the second report without averaging daily ratios.
SELECT
    field_name,
    sum(oil_tonnes) AS oil_tonnes,
    sum(producing_well_days) AS active_well_days,
    sum(oil_tonnes) / nullif(sum(producing_well_days), 0) AS oil_per_active_well_day,
    sum(downtime_hours) AS downtime_hours
FROM oil_mart.v_field_performance
WHERE production_date >= DATE '2025-01-01'
  AND production_date < DATE '2026-01-01'
GROUP BY field_name
ORDER BY oil_tonnes DESC;
