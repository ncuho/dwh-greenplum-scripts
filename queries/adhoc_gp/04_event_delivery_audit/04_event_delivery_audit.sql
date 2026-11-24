-- Считает доставки и уникальные позиции Kafka, а также показывает границы событий по дням приёма.
SELECT (received_at AT TIME ZONE 'UTC')::date AS received_date, kafka_partition,
       count(*) AS deliveries, count(DISTINCT kafka_offset) AS unique_offsets,
       min(kafka_offset) AS first_offset, max(kafka_offset) AS last_offset,
       count(*) FILTER (WHERE event_json::json->>'event_type' = 'production_day') AS production_events
FROM oil_stg.event_log
GROUP BY (received_at AT TIME ZONE 'UTC')::date, kafka_partition ORDER BY received_date DESC, kafka_partition;
