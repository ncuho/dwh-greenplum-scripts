CREATE TABLE ref.product (
    "product_id" integer NOT NULL,
    "product_code" text,
    "product_name" text,
    "unit_code" text,
    "contract_scope" text,
    PRIMARY KEY ("product_id")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.product IS 'One new synthetic commodity; synthetic demonstration, not production certification';
