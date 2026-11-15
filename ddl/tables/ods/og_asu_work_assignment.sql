CREATE TABLE ods.og_asu_work_assignment (
    "assigment_id" bigint,
    "assigment_name" text,
    "work_type" text,
    "assigment_state" text,
    "task_id" bigint,
    "executor_id" bigint
)
DISTRIBUTED BY (assigment_id);

COMMENT ON TABLE ods.og_asu_work_assignment IS 'Назначения работ; synthetic demonstration, not production certification';
