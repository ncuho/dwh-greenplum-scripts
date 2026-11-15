CREATE TABLE ctl.source_asset (
    "asset_name" text NOT NULL,
    "source_fqn" text,
    "snapshot_id" text,
    "row_count" bigint,
    "schema_sha256" text,
    "captured_at" timestamptz,
    PRIMARY KEY ("asset_name")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ctl.source_asset IS 'One source table snapshot definition; synthetic demonstration, not production certification';
