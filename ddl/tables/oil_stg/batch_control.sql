CREATE TABLE oil_stg.batch_control (
    batch_id bigint PRIMARY KEY,
    source_name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    status text NOT NULL CHECK (status IN ('OPEN', 'READY', 'COALESCED', 'APPLIED', 'FAILED')),
    source_manifest text,
    error_text text)
DISTRIBUTED BY (batch_id);
