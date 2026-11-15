CREATE TABLE dm.shipment_balance_month (
    "locality_id" bigint NOT NULL,
    "month_start" date NOT NULL,
    "product_id" integer NOT NULL,
    "opening_m3" numeric(24, 6),
    "received_synthetic_m3" numeric(24, 6),
    "dispatched_m3" numeric(24, 6),
    "closing_m3" numeric(24, 6),
    "revenue_rub" numeric(20, 2),
    "run_id" bigint,
    PRIMARY KEY ("locality_id","month_start","product_id")
)
DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dm.shipment_balance_month IS 'One field/month/product independent physical stock balance; synthetic demonstration, not production certification';
