CREATE TABLE dm.field_month_performance (
    "locality_id" bigint NOT NULL,
    "month_start" date NOT NULL,
    "oil_actual_legacy" numeric(24, 6),
    "oil_plan_legacy" numeric(24, 6),
    "plan_attainment_pct" numeric(12, 6),
    "energy_cost_rub" numeric(20, 2),
    "downtime_hours" numeric(18, 3),
    "run_id" bigint,
    PRIMARY KEY ("locality_id","month_start")
)
DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dm.field_month_performance IS 'One locality/month; synthetic demonstration, not production certification';
