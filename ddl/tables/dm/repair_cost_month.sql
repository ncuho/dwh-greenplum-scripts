CREATE TABLE dm.repair_cost_month (
    "well_id" bigint NOT NULL,
    "month_start" date NOT NULL,
    "repair_count" bigint,
    "labor_hours" numeric(18, 3),
    "labor_cost_rub" numeric(20, 2),
    "material_cost_rub" numeric(20, 2),
    "run_id" bigint,
    PRIMARY KEY ("well_id","month_start")
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dm.repair_cost_month IS 'One well/month repair expense; synthetic demonstration, not production certification';
