CREATE TABLE ctl.task_run (
    "run_id" bigint NOT NULL,
    "batch_id" bigint,
    "task_name" text,
    "attempt" integer,
    "started_at" timestamptz,
    "finished_at" timestamptz,
    "state" text,
    "output_rows" bigint,
    PRIMARY KEY ("run_id")
)
DISTRIBUTED BY (run_id);

COMMENT ON TABLE ctl.task_run IS 'One task attempt in a batch; synthetic demonstration, not production certification';
