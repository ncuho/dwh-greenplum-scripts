CREATE TABLE ctl.quality_result (
    "result_id" bigint NOT NULL,
    "batch_id" bigint,
    "asset_name" text,
    "check_name" text,
    "error_count" bigint,
    "state" text,
    "checked_at" timestamptz,
    PRIMARY KEY ("result_id")
)
DISTRIBUTED BY (result_id);

COMMENT ON TABLE ctl.quality_result IS 'One check result per batch/table; synthetic demonstration, not production certification';
