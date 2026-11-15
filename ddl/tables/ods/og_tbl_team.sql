CREATE TABLE ods.og_tbl_team (
    "id" bigint,
    "title" text,
    "teamlevel" bigint,
    "leader_id" bigint,
    "headou_id" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_team IS 'Группы поддержки; synthetic demonstration, not production certification';
