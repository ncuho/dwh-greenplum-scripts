-- Проверяет соответствие карт объединения партий исходным Kafka-доставкам; ноль означает отсутствие нарушений.
SELECT count(*)
        FROM oil_stg.batch_coalesce_event_map a
        LEFT JOIN oil_stg.batch_coalesce_map m
            ON m.original_batch_id = a.original_batch_id
            AND m.coalesced_batch_id = a.coalesced_batch_id
        LEFT JOIN oil_stg.event_log e
            ON e.topic = a.topic
            AND e.kafka_partition = a.kafka_partition
            AND e.kafka_offset = a.kafka_offset
        WHERE m.original_batch_id IS NULL
            OR e.kafka_offset IS NULL
            OR e.batch_id IS DISTINCT FROM a.coalesced_batch_id;
