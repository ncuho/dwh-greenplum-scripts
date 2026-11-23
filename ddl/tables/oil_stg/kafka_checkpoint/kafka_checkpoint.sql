-- Назначение: Хранит следующий ожидаемый offset каждой партиции. Обновляется в одной транзакции с записью события в GP.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_stg.kafka_checkpoint (
    topic text NOT NULL,
    kafka_partition integer NOT NULL,
    next_offset bigint NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (topic, kafka_partition))
DISTRIBUTED BY (topic, kafka_partition);
