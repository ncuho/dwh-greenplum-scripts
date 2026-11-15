SELECT
    locality_id,
    sample_date,
    analyte,
    sample_count,
    failed_count,
    compliance_pct,
    run_id
FROM dm.quality_compliance_day
ORDER BY locality_id, sample_date, analyte;
