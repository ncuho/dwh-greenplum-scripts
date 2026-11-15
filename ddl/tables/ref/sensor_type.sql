CREATE TABLE ref.sensor_type (
    "sensor_type_id" integer NOT NULL,
    "code" text,
    "unit_code" text,
    "min_valid" numeric(18, 6),
    "max_valid" numeric(18, 6),
    PRIMARY KEY ("sensor_type_id")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.sensor_type IS 'One measured telemetry feature; synthetic demonstration, not production certification';
