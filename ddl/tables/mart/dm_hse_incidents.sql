CREATE TABLE mart.dm_hse_incidents (
    "id" bigint,
    "locality_id" bigint,
    "year" bigint,
    "month" bigint,
    "incident_count" bigint,
    "severity_max" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_hse_incidents IS 'Витрина инцидентов HSE; synthetic demonstration, not production certification';
