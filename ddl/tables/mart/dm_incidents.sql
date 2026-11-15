CREATE TABLE mart.dm_incidents (
    "id" bigint,
    "locality_name" text,
    "incident_count" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_incidents IS 'Витрина инцидентов; synthetic demonstration, not production certification';
