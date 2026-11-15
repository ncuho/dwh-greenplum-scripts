CREATE TABLE mart.dm_well_production (
    "id" bigint,
    "well_id" bigint,
    "locality_id" bigint,
    "year" bigint,
    "month" bigint,
    "total_oil" double precision,
    "total_gas" double precision
)
DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_well_production IS 'Витрина добычи по скважинам; synthetic demonstration, not production certification';
