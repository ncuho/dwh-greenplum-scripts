CREATE TABLE ods.og_tbl_comment (
    "id" bigint,
    "servicecall_id" bigint,
    "author_id" bigint,
    "text" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_comment IS 'Комментарии; synthetic demonstration, not production certification';
