SELECT
    json_build_object('check', 'scd_overlap', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.dim_well_scd2 a
            JOIN dds.dim_well_scd2 b ON a.well_id = b.well_id
                AND a.well_sk < b.well_sk
                AND a.valid_from < b.valid_to
                AND b.valid_from < a.valid_to));

