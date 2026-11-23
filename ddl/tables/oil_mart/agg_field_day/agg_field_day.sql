-- Создаёт таблицу oil_mart.agg_field_day.
CREATE TABLE oil_mart.agg_field_day (
    production_date date NOT NULL,
    field_hk text NOT NULL,
    field_name text NOT NULL,
    region text NOT NULL,
    oil_tonnes numeric(22, 3) NOT NULL,
    producing_well_days bigint NOT NULL,
    oil_per_well_day numeric(22, 6))
DISTRIBUTED BY (field_hk);
