CREATE TABLE ods.og_project (
    "id" bigint,
    "name" text,
    "code" text,
    "status_id" text,
    "director_id" bigint,
    "date_start_plan" date,
    "date_end_plan" date,
    "object_cost" double precision
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_project IS 'Проекты; synthetic demonstration, not production certification';
