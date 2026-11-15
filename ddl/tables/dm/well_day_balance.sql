CREATE TABLE dm.well_day_balance (
    "well_id" bigint NOT NULL,
    "business_date" date NOT NULL,
    "locality_id" bigint,
    "oil_legacy_quantity" numeric(24, 6),
    "plan_oil_legacy" numeric(24, 6),
    "lost_quantity_proxy" numeric(24, 6),
    "downtime_hours" numeric(8, 3),
    "energy_kwh" numeric(20, 6),
    "energy_cost_rub" numeric(20, 2),
    "run_id" bigint
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

COMMENT ON TABLE dm.well_day_balance IS 'One well/day; production energy downtime and loss proxy; synthetic demonstration, not production certification';
