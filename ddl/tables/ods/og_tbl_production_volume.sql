CREATE TABLE ods.og_tbl_production_volume (
    "id" bigint,
    "well_id" bigint,
    "prod_date" date,
    "oil_volume" double precision,
    "gas_volume" double precision,
    "water_volume" double precision
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_production_volume IS 'Добыча (факт); synthetic demonstration, not production certification';
