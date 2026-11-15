SELECT
    measurement.analyte,
    count(*) AS result_count,
    count(measurement.is_compliant) AS assessed_count,
    sum(CASE WHEN measurement.is_compliant IS FALSE THEN 1 ELSE 0 END) AS violation_count,
    sum(CASE WHEN measurement.is_compliant IS NULL THEN 1 ELSE 0 END) AS unknown_count
FROM dds.fact_quality_measurement AS measurement
GROUP BY measurement.analyte
ORDER BY measurement.analyte;
