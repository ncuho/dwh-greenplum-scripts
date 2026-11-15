SELECT
    json_build_object('check', 'daily_expected_count', 'scope', 'new_contract', 'errors', (
            SELECT
                abs(count(*) - (
                    SELECT
                        count(*)
                    FROM ods.og_tbl_well) * (
                    SELECT
                        count(*)
                    FROM ref.calendar))
            FROM dds.fact_production_day));

