-- Read-only visibility required to compare GP exclusive checkpoints with Kafka.
-- Assumes cedrus_gp_ro and USAGE on oil_stg are already managed by the platform.
GRANT SELECT ON oil_stg.kafka_checkpoint TO cedrus_gp_ro;
