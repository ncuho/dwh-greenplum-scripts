CREATE TABLE ctl.publication_release (
    "release_id" bigint NOT NULL,
    "batch_id" bigint,
    "release_state" text,
    "artifact_ref" text,
    "created_at" timestamptz,
    "validation_passed" boolean,
    PRIMARY KEY ("release_id")
)
DISTRIBUTED BY (release_id);

COMMENT ON TABLE ctl.publication_release IS 'One reviewed cross-table release manifest; synthetic demonstration, not production certification';
