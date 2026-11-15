SELECT
    json_build_object('check', 'default_partitions_empty', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_production_day
            WHERE
                business_date < DATE '2025-01-01'
                OR business_date >= DATE '2026-01-01'));

