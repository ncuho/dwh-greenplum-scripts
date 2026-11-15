CREATE TABLE dds.fact_production_day (
    "well_id" bigint NOT NULL,
    "business_date" date NOT NULL,
    "well_sk" bigint,
    "source_month_id" bigint,
    "oil_legacy_quantity" numeric(24, 6),
    "gas_legacy_quantity" numeric(24, 6),
    "water_legacy_quantity" numeric(24, 6),
    "operating_hours" numeric(8, 3),
    "contract_code" text,
    "batch_id" bigint
)
WITH (
    appendonly = true,
    orientation = column,
    compresstype = zlib,
    compresslevel = 3
)
DISTRIBUTED BY (well_id)
PARTITION BY RANGE (business_date) (
    START (DATE '2025-01-01')
    END (DATE '2026-01-01')
    EVERY (INTERVAL '1 month'),
    DEFAULT PARTITION outside_period
);

COMMENT ON TABLE dds.fact_production_day IS 'One well/business date reconciled to original month; synthetic demonstration, not production certification';
