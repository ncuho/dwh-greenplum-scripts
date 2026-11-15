CREATE TABLE ods.og_zgr_it (
    "kod_gr" text,
    "name" text,
    "name_eng" text,
    "gr_pp" text
)
DISTRIBUTED BY (kod_gr);

COMMENT ON TABLE ods.og_zgr_it IS 'Группы ИТ; synthetic demonstration, not production certification';
