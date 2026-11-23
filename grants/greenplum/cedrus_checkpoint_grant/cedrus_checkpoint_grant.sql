-- Разрешает сервисной роли Cedrus читать принятые Kafka offsets для фиксации границы миграции.
GRANT SELECT ON oil_stg.kafka_checkpoint TO cedrus_gp_ro;
