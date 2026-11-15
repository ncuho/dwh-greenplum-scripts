CREATE TABLE ods.og_zcbap_infsys (
    "id" bigint,
    "name" text,
    "short_name" text,
    "teh_name" text,
    "flag_cap" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_zcbap_infsys IS 'Информационные системы; synthetic demonstration, not production certification';
