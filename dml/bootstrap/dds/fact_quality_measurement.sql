INSERT INTO dds.fact_quality_measurement
SELECT
    s.well_id,
    s.sample_id,
    q.analyte,
    CASE q.analyte
    WHEN 'density' THEN
        840 + s.well_id % 30
    WHEN 'water' THEN
        CASE WHEN s.well_id % 19 = 0 THEN
            1.5
        ELSE
            0.3
        END
    ELSE
        30 + s.well_id % 20
    END,
    q.unit_code,
    q.spec_id,
    NOT (q.analyte = 'water'
        AND s.well_id % 19 = 0),
    1
FROM
    dds.fact_lab_sample s
    JOIN ref.quality_spec q ON q.product_id = s.product_id
        AND s.sampled_at >= q.valid_from
        AND s.sampled_at < q.valid_to;

