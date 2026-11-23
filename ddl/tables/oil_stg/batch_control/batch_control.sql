-- Назначение: Хранит жизненный цикл партии: OPEN, READY, COALESCED, APPLIED или FAILED. Отделяет успешную доставку от применения в DDS.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_stg.batch_control (
    batch_id bigint PRIMARY KEY,
    source_name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    status text NOT NULL CHECK (status IN ('OPEN', 'READY', 'COALESCED', 'APPLIED', 'FAILED')),
    source_manifest text,
    error_text text)
DISTRIBUTED BY (batch_id);
