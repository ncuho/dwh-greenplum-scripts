-- Apply only after reviewed webinar-chain GP schema, as a controlled change.
-- PostgreSQL-compatible syntax is a proposal: verify on the installed GP6.
CREATE SEQUENCE demo_stg.kafka_batch_id_seq START 1000000000;
CREATE TABLE demo_stg.kafka_checkpoint (
    topic text NOT NULL,
    kafka_partition integer NOT NULL,
    next_offset bigint NOT NULL CHECK (next_offset >= 0),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (topic, kafka_partition)
) DISTRIBUTED BY (topic, kafka_partition);
-- A reviewed operator must explicitly INSERT one initial next_offset per
-- assigned partition, after checking broker watermarks and the migration plan.
-- No rows are initialized automatically: fixture offsets are not Kafka offsets.
