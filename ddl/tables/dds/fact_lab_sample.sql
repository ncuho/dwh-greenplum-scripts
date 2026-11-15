CREATE TABLE dds.fact_lab_sample (
    "sample_id" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "sampled_at" timestamp,
    "product_id" integer,
    "laboratory_code" text,
    "batch_id" bigint,
    PRIMARY KEY ("well_id","sample_id")
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_lab_sample IS 'One well/month physical sample; synthetic demonstration, not production certification';
