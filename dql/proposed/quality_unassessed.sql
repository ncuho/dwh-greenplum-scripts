SELECT
    well_id,
    analyte,
    count(*) AS results,
    sum(CASE WHEN is_compliant IS NULL THEN 1 ELSE 0 END) AS unassessed
FROM dds.fact_quality_measurement
GROUP BY well_id, analyte
HAVING sum(CASE WHEN is_compliant IS NULL THEN 1 ELSE 0 END) > 0
ORDER BY well_id, analyte;
