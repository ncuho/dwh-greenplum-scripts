-- Назначение: Принимает исходные JSON-события вместе с topic, partition, offset и ID партии. Сохраняет доставку до применения бизнес-логики.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_stg.event_log (
    topic text NOT NULL,
    kafka_partition integer NOT NULL,
    kafka_offset bigint NOT NULL,
    batch_id bigint NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),
    event_json text NOT NULL,
    PRIMARY KEY (topic, kafka_partition, kafka_offset))
DISTRIBUTED BY (topic, kafka_partition);
