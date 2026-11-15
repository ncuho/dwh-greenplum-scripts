CREATE TABLE ref.downtime_reason (
    "reason_id" integer NOT NULL,
    "code" text,
    "planned" boolean,
    "description" text,
    PRIMARY KEY ("reason_id")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.downtime_reason IS 'One mutually classified reason; synthetic demonstration, not production certification';
