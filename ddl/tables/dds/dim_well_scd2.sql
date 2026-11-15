CREATE TABLE dds.dim_well_scd2 (
    "well_sk" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "locality_id" bigint,
    "valid_from" date,
    "valid_to" date,
    "pump_mode" text,
    "nominal_load_kw" numeric(12, 3),
    "is_current" boolean,
    PRIMARY KEY ("well_id","well_sk")
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.dim_well_scd2 IS 'One well attribute version [valid_from,valid_to); synthetic demonstration, not production certification';
