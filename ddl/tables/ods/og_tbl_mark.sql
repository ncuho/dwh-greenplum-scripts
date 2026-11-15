CREATE TABLE ods.og_tbl_mark (
    "id" bigint,
    "code" text,
    "color" text,
    "title" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_mark IS 'Отметки; synthetic demonstration, not production certification';
