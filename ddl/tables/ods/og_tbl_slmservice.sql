CREATE TABLE ods.og_tbl_slmservice (
    "id" bigint,
    "title" text,
    "state_" text,
    "responsibleteam_id" bigint,
    "customer_ou" bigint,
    "classification" text,
    "rating" double precision,
    "informsystem" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_slmservice IS 'SLA-сервисы; synthetic demonstration, not production certification';
