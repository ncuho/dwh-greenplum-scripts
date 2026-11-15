CREATE TABLE dds.bridge_equipment_well_history (
    "well_id" bigint NOT NULL,
    "equipment_id" bigint NOT NULL,
    "valid_from" date NOT NULL,
    "valid_to" date,
    PRIMARY KEY ("well_id","equipment_id","valid_from")
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.bridge_equipment_well_history IS 'One equipment installation interval; synthetic demonstration, not production certification';
