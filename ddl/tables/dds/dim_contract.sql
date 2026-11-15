CREATE TABLE dds.dim_contract (
    "contract_id" bigint NOT NULL,
    "contractor_company_id" bigint,
    "valid_from" date,
    "valid_to" date,
    "hour_rate_rub" numeric(14, 2),
    "currency_code" text,
    PRIMARY KEY ("contract_id")
)
DISTRIBUTED BY (contract_id);

COMMENT ON TABLE dds.dim_contract IS 'One synthetic contractor agreement; synthetic demonstration, not production certification';
