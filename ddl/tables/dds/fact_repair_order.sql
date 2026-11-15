CREATE TABLE dds.fact_repair_order (
    "repair_order_id" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "equipment_id" bigint,
    "contract_id" bigint,
    "repair_type_id" integer,
    "opened_at" timestamp,
    "closed_at" timestamp,
    "status" ref.work_state,
    "source_repair_id" bigint,
    "batch_id" bigint,
    PRIMARY KEY ("well_id","repair_order_id")
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_repair_order IS 'One new repair order (not a clone of source repair); synthetic demonstration, not production certification';
