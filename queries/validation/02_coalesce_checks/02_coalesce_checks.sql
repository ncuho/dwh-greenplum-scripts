-- Назначение: Read-only SQL-проверки объединения партий и сохранения происхождения.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
-- Read-only; replace :new_batch_id with a validated numeric batch ID in psql.
-- These checks do not establish Kafka end offset or snapshot consistency.
SELECT
    b.batch_id,
    b.status,
    b.source_name,
    count(e.kafka_offset) event_count
FROM
    oil_stg.batch_control b
    LEFT JOIN oil_stg.event_log e ON e.batch_id = b.batch_id
WHERE
    b.batch_id = :new_batch_id
GROUP BY
    b.batch_id,
    b.status,
    b.source_name;

SELECT
    m.original_batch_id,
    m.original_event_count,
    count(em.kafka_offset) mapped_events,
    b.status
FROM
    oil_stg.batch_coalesce_map m
    JOIN oil_stg.batch_control b ON b.batch_id = m.original_batch_id
    LEFT JOIN oil_stg.batch_coalesce_event_map em ON em.original_batch_id = m.original_batch_id
        AND em.coalesced_batch_id = m.coalesced_batch_id
WHERE
    m.coalesced_batch_id = :new_batch_id
GROUP BY
    m.original_batch_id,
    m.original_event_count,
    b.status
HAVING
    m.original_event_count <> count(em.kafka_offset)
    OR b.status <> 'COALESCED';

SELECT
    count(*) AS mapping_mismatches
FROM
    oil_stg.batch_coalesce_event_map m
    LEFT JOIN oil_stg.event_log e ON e.topic = m.topic
        AND e.kafka_partition = m.kafka_partition
        AND e.kafka_offset = m.kafka_offset
WHERE
    m.coalesced_batch_id = :new_batch_id
    AND (e.kafka_offset IS NULL
        OR e.batch_id <> m.coalesced_batch_id);

SELECT
    e.topic,
    e.kafka_partition,
    min(e.kafka_offset) min_offset,
    max(e.kafka_offset) max_offset,
    count(*) records
FROM
    oil_stg.event_log e
WHERE
    e.batch_id = :new_batch_id
GROUP BY
    e.topic,
    e.kafka_partition
ORDER BY
    e.topic,
    e.kafka_partition;

-- min/max do NOT prove no gaps: compare complete offsets with Kafka and checkpoint.
