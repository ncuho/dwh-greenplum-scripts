-- Назначение: Историческое измерение месторождения. Интервал действия версии — [valid_from, valid_to); удаление сохраняется отдельным признаком.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_mart.dim_field (
    field_hk text NOT NULL,
    entity_version bigint NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_to timestamptz,
    field_name text,
    region text,
    is_deleted boolean NOT NULL)
DISTRIBUTED BY (field_hk);
