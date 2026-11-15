CREATE TABLE mart.dm_hse_one (
    "id" bigint,
    "incident_type" text,
    "severity" text,
    "timebegin" timestamp without time zone,
    "well_id" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_hse_one IS 'Витрина HSE (единая); synthetic demonstration, not production certification';
