INSERT INTO stg.lab_event
SELECT
    m.sample_id * 10 + m.spec_id,
    'lab:' || m.sample_id || ':' || m.analyte,
    m.well_id,
    s.sampled_at,
    json_build_object('analyte', m.analyte, 'value', m.measured_value, 'unit', m.unit_code),
    m.batch_id
FROM
    dds.fact_quality_measurement m
    JOIN dds.fact_lab_sample s ON s.well_id = m.well_id
        AND s.sample_id = m.sample_id;

