-- Показывает число версий и изменение объёма добычи между самой ранней и последней версией события.
WITH versions AS (
    SELECT production_hk, event_id, entity_version, op, production_date, oil_tonnes,
           row_number() OVER (PARTITION BY production_hk ORDER BY entity_version, event_id) AS first_n,
           row_number() OVER (PARTITION BY production_hk ORDER BY entity_version DESC, event_id DESC) AS last_n,
           count(*) OVER (PARTITION BY production_hk) AS revision_count
    FROM oil_dds.sat_daily_production
)
SELECT production_hk, min(production_date) AS production_date, max(revision_count) AS revision_count,
       max(oil_tonnes) FILTER (WHERE first_n = 1) AS first_tonnes,
       max(oil_tonnes) FILTER (WHERE last_n = 1) AS latest_tonnes,
       max(oil_tonnes) FILTER (WHERE last_n = 1) - max(oil_tonnes) FILTER (WHERE first_n = 1) AS correction_tonnes,
       max(op) FILTER (WHERE last_n = 1) AS latest_op
FROM versions GROUP BY production_hk HAVING max(revision_count) > 1
ORDER BY revision_count DESC, production_hk LIMIT 20;
