SELECT
    versions.well_id,
    versions.well_sk,
    versions.valid_from,
    versions.valid_to,
    versions.previous_end,
    CASE
        WHEN versions.previous_end > versions.valid_from THEN 'overlap'
        WHEN versions.previous_end < versions.valid_from THEN 'gap'
    END AS issue
FROM (
    SELECT
        well_id,
        well_sk,
        valid_from,
        valid_to,
        lag(valid_to) OVER (
            PARTITION BY well_id
            ORDER BY valid_from, well_sk
        ) AS previous_end
    FROM dds.dim_well_scd2
) AS versions
WHERE versions.previous_end IS NOT NULL
  AND versions.valid_from IS NOT NULL
  AND versions.previous_end <> versions.valid_from
ORDER BY versions.well_id, versions.valid_from, versions.well_sk;
