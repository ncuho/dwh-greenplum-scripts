CREATE TABLE dds.fact_shipment_item (
    "locality_id" bigint NOT NULL,
    "shipment_id" bigint NOT NULL,
    "line_no" integer NOT NULL,
    "product_id" integer,
    "quantity_m3" numeric(20, 6),
    "density_kg_m3" numeric(12, 6),
    "amount_rub" numeric(20, 2),
    "batch_id" bigint
)
WITH (
    appendonly = true,
    orientation = row,
    compresstype = zlib,
    compresslevel = 3
)
DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dds.fact_shipment_item IS 'One product line of dispatch; synthetic demonstration, not production certification';
