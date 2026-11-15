SELECT
    batch_id,
    source_event_key,
    count(*) AS row_count
FROM stg.ext_repair_event
GROUP BY batch_id, source_event_key
HAVING source_event_key IS NULL OR count(*) > 1
ORDER BY batch_id, source_event_key;
