CREATE TABLE ods.og_tbl_changerequest (
    "id" bigint,
    "title" text,
    "state" text,
    "responsibleemployee_id" bigint,
    "responsibleteam_id" bigint,
    "impact" text,
    "category" text,
    "code" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_changerequest IS 'Запросы на изменения (Change Management); synthetic demonstration, not production certification';
