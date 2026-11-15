-- Prepared definition, not installed on the source database.
CREATE VIEW dm.v_quality_assessment_by_well AS
SELECT
    well_id,
    analyte,
    count(*) AS result_count,
    count(is_compliant) AS assessed_count,
    sum(CASE WHEN is_compliant IS FALSE THEN 1 ELSE 0 END) AS violation_count,
    sum(CASE WHEN is_compliant IS NULL THEN 1 ELSE 0 END) AS unknown_count
FROM dds.fact_quality_measurement
GROUP BY well_id, analyte;
