CREATE TABLE dds.dim_equipment (
    "equipment_id" bigint NOT NULL,
    "equipment_code" text,
    "equipment_type" text,
    "commissioned_on" date,
    "rated_kw" numeric(12, 3),
    PRIMARY KEY ("equipment_id")
)
DISTRIBUTED BY (equipment_id);

COMMENT ON TABLE dds.dim_equipment IS 'One synthetic installed unit; synthetic demonstration, not production certification';
