-- Назначение: Реестр принятых событий DDS. event_id определяет повтор, entity_version задаёт порядок изменений, event_document позволяет сверить историю.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_dds.event (
    event_id text PRIMARY KEY,
    event_type text NOT NULL,
    entity_id text NOT NULL,
    entity_version bigint NOT NULL,
    op text NOT NULL,
    event_time timestamptz NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    batch_id bigint NOT NULL,
    payload text NOT NULL,
    event_document text NOT NULL)
DISTRIBUTED BY (event_id);
