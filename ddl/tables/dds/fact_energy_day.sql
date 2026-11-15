CREATE TABLE dds.fact_energy_day (
    "well_id" bigint NOT NULL,
    "business_date" date NOT NULL,
    "tariff_id" integer,
    "energy_kwh" numeric(20, 6),
    "energy_cost_rub" numeric(20, 2),
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

COMMENT ON TABLE dds.fact_energy_day IS 'One well/day electricity bill allocation; synthetic demonstration, not production certification';
