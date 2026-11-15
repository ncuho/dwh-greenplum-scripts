CREATE TABLE ods.og_tbl_kb (
    "id" bigint,
    "title" text,
    "responsibleteam_id" bigint,
    "author_id" bigint,
    "viewcounter" bigint,
    "state" text,
    "kbsection_basedcateg" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_kb IS 'База знаний; synthetic demonstration, not production certification';
