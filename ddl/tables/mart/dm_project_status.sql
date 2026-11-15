CREATE TABLE mart.dm_project_status (
    "id" bigint,
    "director_id" bigint,
    "status" text,
    "project_count" bigint,
    "total_cost" double precision
)
DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_project_status IS 'Витрина статусов проектов; synthetic demonstration, not production certification';
