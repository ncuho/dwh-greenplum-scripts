-- Назначение: Хранит бизнес-идентификатор месторождения и детерминированный hash key. Не содержит изменяемых описательных атрибутов.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_dds.hub_field (
    field_hk text NOT NULL,
    field_id text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (field_hk);
