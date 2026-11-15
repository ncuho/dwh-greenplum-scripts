CREATE TABLE ods.og_pa0002 (
    "pernr" bigint,
    "nachn" text,
    "vorna" text,
    "midnm" text,
    "gesch" text,
    "gbdat" date,
    "natio" text
)
DISTRIBUTED BY (pernr);

COMMENT ON TABLE ods.og_pa0002 IS 'Личные данные (SAP HR); synthetic demonstration, not production certification';
