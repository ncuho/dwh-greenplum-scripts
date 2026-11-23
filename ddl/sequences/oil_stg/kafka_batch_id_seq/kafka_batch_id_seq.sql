-- Создаёт последовательность идентификаторов новых Kafka-партий, начиная с 5000000000.
CREATE SEQUENCE oil_stg.kafka_batch_id_seq
    START 5000000000;
