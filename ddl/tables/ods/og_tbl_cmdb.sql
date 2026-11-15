CREATE TABLE ods.og_tbl_cmdb (
    "id" bigint,
    "title" text,
    "ci_hostname" text,
    "ci_ip" text,
    "state" text,
    "responsibleteam_id" bigint,
    "ci_bservice" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_cmdb IS 'Конфигурационные единицы; synthetic demonstration, not production certification';
