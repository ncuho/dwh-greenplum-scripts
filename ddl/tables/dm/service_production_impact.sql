CREATE TABLE dm.service_production_impact (
    "servicecall_id" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "linked_date" date,
    "association_basis" text,
    "is_causal_evidence" boolean,
    "downtime_hours" numeric(10, 3),
    "run_id" bigint,
    PRIMARY KEY ("servicecall_id","well_id")
)
DISTRIBUTED BY (well_id);

COMMENT ON TABLE dm.service_production_impact IS 'One explicitly synthetic service-to-well linkage assessment; synthetic demonstration, not production certification';
