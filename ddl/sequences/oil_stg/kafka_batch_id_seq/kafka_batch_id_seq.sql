-- Назначение: Выдаёт уникальные ID партий единственному Kafka writer.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
-- Apply in the selected oil GP database only after backup/owner review.
-- Reserve this ID range for the single Kafka writer; coordinate any fixture IDs.
CREATE SEQUENCE oil_stg.kafka_batch_id_seq
    START 5000000000;

-- Explicitly initialize one checkpoint row per topic partition AFTER capturing
-- and approving actual initial broker offsets. Never use fixture offsets here.
-- INSERT INTO oil_stg.kafka_checkpoint(topic, kafka_partition, next_offset)
-- VALUES ('oil.events.v1', 0, <REVIEWED_NEXT_OFFSET>);
