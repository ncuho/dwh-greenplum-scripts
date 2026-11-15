CREATE TABLE ods.og_but000 (
    "partner" text,
    "type" text,
    "name_org1" text,
    "name_last" text,
    "name_first" text,
    "namemiddle" text,
    "ind_sector" text,
    "location_1" text,
    "found_dat" date
)
DISTRIBUTED BY (partner);

COMMENT ON TABLE ods.og_but000 IS 'Контрагенты (SAP BP); synthetic demonstration, not production certification';
