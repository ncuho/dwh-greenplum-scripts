CREATE TABLE ods.og_tbl_directory (
    "id" bigint,
    "title" text,
    "code" text,
    "type" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_directory IS 'Справочник объектов; synthetic demonstration, not production certification';
