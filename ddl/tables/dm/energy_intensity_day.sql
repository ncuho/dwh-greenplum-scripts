CREATE TABLE dm.energy_intensity_day (
    "well_id" bigint NOT NULL,
    "business_date" date NOT NULL,
    "energy_kwh" numeric(20, 6),
    "oil_legacy_quantity" numeric(24, 6),
    "kwh_per_legacy_unit" numeric(24, 6),
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

COMMENT ON TABLE dm.energy_intensity_day IS 'One well/day including undefined zero-production intensity; synthetic demonstration, not production certification';
