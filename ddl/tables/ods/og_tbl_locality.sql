CREATE TABLE ods.og_tbl_locality (
    "id" bigint,
    "dbid" text,
    "name" text,
    "region" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_locality IS 'Месторождения (нефтегазовые); synthetic demonstration, not production certification';
