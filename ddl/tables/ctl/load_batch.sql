CREATE TABLE ctl.load_batch (
    "batch_id" bigint NOT NULL,
    "source_system" text,
    "source_cut_ref" text,
    "seed" bigint,
    "started_at" timestamptz,
    "finished_at" timestamptz,
    "state" text,
    PRIMARY KEY ("batch_id")
)
DISTRIBUTED BY (batch_id);

COMMENT ON TABLE ctl.load_batch IS 'One immutable input batch identity; synthetic demonstration, not production certification';
