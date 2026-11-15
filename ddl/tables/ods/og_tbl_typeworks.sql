CREATE TABLE ods.og_tbl_typeworks (
    "id" bigint,
    "title" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_typeworks IS 'Виды работ; synthetic demonstration, not production certification';
