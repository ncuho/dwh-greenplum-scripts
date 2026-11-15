CREATE TABLE ods.og_tbl_well (
    "id" bigint,
    "fieldid" bigint,
    "title" text,
    "depth" double precision,
    "state" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_well IS 'Скважины; synthetic demonstration, not production certification';
