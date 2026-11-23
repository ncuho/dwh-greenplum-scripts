-- Назначение: Структура регистрации отклонённых событий. Автоматическое заполнение при ошибке apply не включено: некорректная партия откатывается.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_stg.event_reject (
    topic text,
    kafka_partition integer,
    kafka_offset bigint,
    event_json text,
    reason text NOT NULL,
    rejected_at timestamptz NOT NULL DEFAULT now())
DISTRIBUTED BY (topic, kafka_partition);
