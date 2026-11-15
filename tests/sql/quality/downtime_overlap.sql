SELECT
    json_build_object('check', 'downtime_overlap', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dds.fact_downtime_interval a
            JOIN dds.fact_downtime_interval b ON a.well_id = b.well_id
                AND a.downtime_id < b.downtime_id
                AND a.starts_at < b.ends_at
                AND b.starts_at < a.ends_at));

