-- Выбирает десять скважин с максимальной добычей, связывая факт с точной исторической версией измерения.
SELECT w.well_name, sum(f.oil_tonnes) AS oil_tonnes,
       count(*) FILTER (WHERE f.status = 'ACTIVE') AS producing_days,
       round(avg(f.oil_tonnes), 3) AS average_day_tonnes
FROM oil_mart.fact_well_day f
JOIN oil_mart.dim_well w ON w.well_hk = f.well_hk AND w.entity_version = f.well_version
WHERE f.production_date >= DATE '2025-01-01' AND f.production_date < DATE '2026-01-01'
GROUP BY w.well_name ORDER BY oil_tonnes DESC LIMIT 10;
