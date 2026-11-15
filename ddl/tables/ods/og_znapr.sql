CREATE TABLE ods.og_znapr (
    "kod_napr" text,
    "name" text,
    "name_eng" text
)
DISTRIBUTED BY (kod_napr);

COMMENT ON TABLE ods.og_znapr IS 'Направления деятельности; synthetic demonstration, not production certification';
