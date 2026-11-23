-- Создаёт таблицу oil_mart.dim_well.
CREATE TABLE oil_mart.dim_well (
    well_hk text NOT NULL,
    field_hk text NOT NULL,
    entity_version bigint NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    well_name text,
    status text,
    is_deleted boolean NOT NULL)
DISTRIBUTED BY (well_hk);
