CREATE TABLE ods.og_pa0001 (
    "pernr" bigint,
    "bukrs" text,
    "werks" text,
    "orgeh" text,
    "stell" text
)
DISTRIBUTED BY (pernr);

COMMENT ON TABLE ods.og_pa0001 IS 'Штатная расстановка (SAP HR); synthetic demonstration, not production certification';
