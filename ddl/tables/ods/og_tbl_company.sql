CREATE TABLE ods.og_tbl_company (
    "id" bigint,
    "dbid" text,
    "fullname" text,
    "company_type" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_company IS 'Компании-подрядчики; synthetic demonstration, not production certification';
