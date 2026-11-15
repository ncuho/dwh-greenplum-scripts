CREATE TABLE ods.og_tbl_workrecord (
    "id" bigint,
    "servicecall" bigint,
    "employee" bigint,
    "workrecordkb_typeworks" bigint,
    "time" double precision,
    "client_ou" bigint,
    "state" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_workrecord IS 'Записи работ; synthetic demonstration, not production certification';
