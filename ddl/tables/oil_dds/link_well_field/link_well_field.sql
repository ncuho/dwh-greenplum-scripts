-- Создаёт таблицу oil_dds.link_well_field.
CREATE TABLE oil_dds.link_well_field (
    link_hk text NOT NULL,
    well_hk text NOT NULL,
    field_hk text NOT NULL,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL)
DISTRIBUTED BY (well_hk);
