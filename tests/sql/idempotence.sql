BEGIN;
CREATE TEMP TABLE before_marts ON COMMIT DROP AS
SELECT
    'dm.well_day_balance'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.well_day_balance x
UNION ALL
SELECT
    'dm.field_month_performance'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.field_month_performance x
UNION ALL
SELECT
    'dm.repair_cost_month'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.repair_cost_month x
UNION ALL
SELECT
    'dm.energy_intensity_day'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.energy_intensity_day x
UNION ALL
SELECT
    'dm.quality_compliance_day'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.quality_compliance_day x
UNION ALL
SELECT
    'dm.shipment_balance_month'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.shipment_balance_month x
UNION ALL
SELECT
    'dm.service_production_impact'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.service_production_impact x DISTRIBUTED RANDOMLY;
SELECT
    etl.run_daily_batch (1, date '2025-01-01', date '2026-01-01', 2);
CREATE TEMP TABLE after_marts ON COMMIT DROP AS
SELECT
    'dm.well_day_balance'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.well_day_balance x
UNION ALL
SELECT
    'dm.field_month_performance'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.field_month_performance x
UNION ALL
SELECT
    'dm.repair_cost_month'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.repair_cost_month x
UNION ALL
SELECT
    'dm.energy_intensity_day'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.energy_intensity_day x
UNION ALL
SELECT
    'dm.quality_compliance_day'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.quality_compliance_day x
UNION ALL
SELECT
    'dm.shipment_balance_month'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.shipment_balance_month x
UNION ALL
SELECT
    'dm.service_production_impact'::text AS asset, row_to_json(x)::text AS payload
FROM
    dm.service_production_impact x DISTRIBUTED RANDOMLY;
SELECT
    'idempotent_multiset_differences',
    count(*)
FROM ((
        SELECT
            *
        FROM
            before_marts
        EXCEPT ALL
        SELECT
            *
        FROM
            after_marts)
    UNION ALL (
        SELECT
            *
        FROM
            after_marts
        EXCEPT ALL
        SELECT
            *
        FROM
            before_marts)) d;
ROLLBACK;

