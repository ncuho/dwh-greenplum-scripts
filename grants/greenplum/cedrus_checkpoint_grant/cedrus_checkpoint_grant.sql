-- Назначение: Назначает минимальные права чтения checkpoint при согласовании границы.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
-- Read-only visibility required to compare GP exclusive checkpoints with Kafka.
-- Assumes cedrus_gp_ro and USAGE on oil_stg are already managed by the platform.
GRANT SELECT ON oil_stg.kafka_checkpoint TO cedrus_gp_ro;
