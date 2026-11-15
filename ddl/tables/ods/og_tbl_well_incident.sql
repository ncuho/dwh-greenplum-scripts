CREATE TABLE ods.og_tbl_well_incident (
    "id" bigint,
    "well_id" bigint,
    "timebegin" timestamp without time zone,
    "incident_type" text,
    "severity" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_well_incident IS 'Инциденты на скважинах (HSE); synthetic demonstration, not production certification';
