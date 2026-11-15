CREATE TABLE dds.fact_repair_operation (
    "operation_id" bigint NOT NULL,
    "repair_order_id" bigint,
    "well_id" bigint NOT NULL,
    "operation_code" text,
    "labor_hours" numeric(12, 3),
    "material_cost_rub" numeric(18, 2),
    "labor_cost_rub" numeric(18, 2),
    "batch_id" bigint
)
WITH (
    appendonly = true,
    orientation = row,
    compresstype = zlib,
    compresslevel = 3
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_repair_operation IS 'One work operation within repair; synthetic demonstration, not production certification';
