CREATE TABLE ref.unit (
    "unit_code" text NOT NULL,
    "symbol" text,
    "description" text,
    "physical" boolean,
    PRIMARY KEY ("unit_code")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.unit IS 'One declared measure unit; synthetic demonstration, not production certification';
