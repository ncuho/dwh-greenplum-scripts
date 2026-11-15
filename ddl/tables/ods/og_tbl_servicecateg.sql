CREATE TABLE ods.og_tbl_servicecateg (
    "id" bigint,
    "title" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_servicecateg IS 'Категории услуг; synthetic demonstration, not production certification';
