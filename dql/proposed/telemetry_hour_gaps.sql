SELECT
    current_row.well_id,
    current_row.event_ts AS previous_event_ts,
    current_row.next_event_ts,
    current_row.next_event_ts - current_row.event_ts AS observed_interval
FROM (
    SELECT
        well_id,
        event_ts,
        lead(event_ts) OVER (PARTITION BY well_id ORDER BY event_ts) AS next_event_ts
    FROM dds.fact_telemetry_hour
) AS current_row
WHERE current_row.next_event_ts > current_row.event_ts + interval '1 hour'
ORDER BY current_row.well_id, current_row.event_ts;
