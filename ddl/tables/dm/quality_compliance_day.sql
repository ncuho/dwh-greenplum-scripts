CREATE TABLE dm.quality_compliance_day (
    "locality_id" bigint NOT NULL,
    "sample_date" date NOT NULL,
    "analyte" text NOT NULL,
    "sample_count" bigint,
    "failed_count" bigint,
    "compliance_pct" numeric(10, 4),
    "run_id" bigint,
    PRIMARY KEY ("locality_id","sample_date","analyte")
)
DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dm.quality_compliance_day IS 'One field/sampleday/analyte; synthetic demonstration, not production certification';
