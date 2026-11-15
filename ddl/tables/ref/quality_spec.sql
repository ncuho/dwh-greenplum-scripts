CREATE TABLE ref.quality_spec (
    "spec_id" integer NOT NULL,
    "product_id" integer,
    "analyte" text,
    "unit_code" text,
    "min_value" numeric(18, 6),
    "max_value" numeric(18, 6),
    "valid_from" date,
    "valid_to" date,
    PRIMARY KEY ("spec_id")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.quality_spec IS 'One product/analyte/effective specification; synthetic demonstration, not production certification';
