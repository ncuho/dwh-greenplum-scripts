-- Назначение: Хранит историческую связь интервала простоя со скважиной по техническим ключам. Изменяемые атрибуты находятся в satellites.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_dds.link_downtime_well (
    link_hk text NOT NULL,
    downtime_hk text NOT NULL,
    well_hk text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (downtime_hk);
