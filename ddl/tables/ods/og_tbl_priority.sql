CREATE TABLE ods.og_tbl_priority (
    "id" bigint,
    "title" text,
    "priority_level" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_priority IS 'Приоритеты заявок; synthetic demonstration, not production certification';
