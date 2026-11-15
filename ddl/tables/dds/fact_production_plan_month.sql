CREATE TABLE dds.fact_production_plan_month (
    "well_id" bigint NOT NULL,
    "month_start" date NOT NULL,
    "scenario" text NOT NULL,
    "oil_plan_legacy" numeric(24, 6),
    "gas_plan_legacy" numeric(24, 6),
    "energy_budget_kwh" numeric(20, 6),
    "batch_id" bigint,
    PRIMARY KEY ("well_id","month_start","scenario")
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_production_plan_month IS 'One well/month/scenario plan; synthetic demonstration, not production certification';
