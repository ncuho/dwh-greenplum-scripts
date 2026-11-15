CREATE TABLE mart.dm_well (
    "id" bigint,
    "well_id" bigint,
    "well_state" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_well IS 'Витрина скважин; synthetic demonstration, not production certification';
