SELECT
    json_build_object('check', 'scd_fact_one_version', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    p.well_id, p.business_date
                FROM dds.fact_production_day p
            LEFT JOIN dds.dim_well_scd2 s ON s.well_id = p.well_id
                AND p.business_date >= s.valid_from
                AND p.business_date < s.valid_to GROUP BY 1, 2
        HAVING
            count(s.well_sk) <> 1) d));

