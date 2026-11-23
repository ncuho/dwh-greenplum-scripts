-- Создаёт таблицу oil_dds.link_production_day_well.
CREATE TABLE oil_dds.link_production_day_well (
    link_hk text NOT NULL,
    production_hk text NOT NULL,
    well_hk text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (production_hk);
