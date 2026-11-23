-- Создаёт таблицу oil_stg.batch_coalesce_event_map.
CREATE TABLE oil_stg.batch_coalesce_event_map (
    topic text NOT NULL,
    kafka_partition integer NOT NULL,
    kafka_offset bigint NOT NULL,
    original_batch_id bigint NOT NULL,
    coalesced_batch_id bigint NOT NULL,
    PRIMARY KEY (topic, kafka_partition, kafka_offset))
DISTRIBUTED BY (topic, kafka_partition);
