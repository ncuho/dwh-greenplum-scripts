-- Создаёт таблицу oil_stg.event_log.
CREATE TABLE oil_stg.event_log (
    topic text NOT NULL,
    kafka_partition integer NOT NULL,
    kafka_offset bigint NOT NULL,
    batch_id bigint NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),
    event_json text NOT NULL,
    PRIMARY KEY (topic, kafka_partition, kafka_offset))
DISTRIBUTED BY (topic, kafka_partition);
