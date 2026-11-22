-- Greenplum: trace a fact to its historical dimension version; read-only.
SELECT
    f.production_date,
    w.well_name,
    f.well_version,
    f.oil_tonnes,
    f.status
FROM oil_mart.fact_well_day f
JOIN oil_mart.dim_well w
    ON w.well_hk = f.well_hk
    AND w.entity_version = f.well_version
ORDER BY f.production_date, w.well_name
LIMIT 25;
