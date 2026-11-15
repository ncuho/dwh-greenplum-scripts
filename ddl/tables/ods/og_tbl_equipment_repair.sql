CREATE TABLE ods.og_tbl_equipment_repair (
    "id" bigint,
    "factbegindate" timestamp without time zone,
    "factenddate" timestamp without time zone,
    "wellid" bigint,
    "contractor_id" bigint,
    "cost" double precision
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_equipment_repair IS 'Ремонты оборудования; synthetic demonstration, not production certification';
