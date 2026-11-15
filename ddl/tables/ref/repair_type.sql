CREATE TABLE ref.repair_type (
    "repair_type_id" integer NOT NULL,
    "code" text,
    "description" text,
    "standard_hours" numeric(10, 2),
    PRIMARY KEY ("repair_type_id")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.repair_type IS 'One repair activity type; synthetic demonstration, not production certification';
