-- Создаёт таблицу oil_stg.event_reject.
CREATE TABLE oil_stg.event_reject (
    topic text,
    kafka_partition integer,
    kafka_offset bigint,
    event_json text,
    reason text NOT NULL,
    rejected_at timestamptz NOT NULL DEFAULT now())
DISTRIBUTED BY (topic, kafka_partition);
