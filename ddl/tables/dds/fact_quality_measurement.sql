CREATE TABLE dds.fact_quality_measurement (
    "well_id" bigint NOT NULL,
    "sample_id" bigint NOT NULL,
    "analyte" text NOT NULL,
    "measured_value" numeric(18, 6),
    "unit_code" text,
    "spec_id" integer,
    "is_compliant" boolean,
    "batch_id" bigint
)
WITH (
    appendonly = true,
    orientation = row,
    compresstype = zlib,
    compresslevel = 3
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_quality_measurement IS 'One analyte result per sample; synthetic demonstration, not production certification';
