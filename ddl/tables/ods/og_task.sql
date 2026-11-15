CREATE TABLE ods.og_task (
    "task_id" bigint,
    "task_title" text,
    "task_desc" text,
    "task_hours" double precision,
    "task_project_id" bigint,
    "task_status_id" bigint,
    "assigned_ws_user_id" bigint,
    "task_priority_id" bigint,
    "task_target_finish" timestamp without time zone,
    "task_completed" timestamp without time zone
)
DISTRIBUTED BY (task_id);

COMMENT ON TABLE ods.og_task IS 'Задачи проектов; synthetic demonstration, not production certification';
