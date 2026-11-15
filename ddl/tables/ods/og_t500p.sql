CREATE TABLE ods.og_t500p (
    "persa" text,
    "molga" text,
    "name1" text
)
DISTRIBUTED BY (persa);

COMMENT ON TABLE ods.og_t500p IS 'Персонал-области; synthetic demonstration, not production certification';
