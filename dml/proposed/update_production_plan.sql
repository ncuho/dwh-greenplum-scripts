-- Prepared change, not deployed. The caller must supply all five psql variables:
-- well_id, month_start, scenario, expected_oil_plan and new_oil_plan.
-- Requires authorization and review of the affected row before COMMIT.
\set ON_ERROR_STOP on
BEGIN;

UPDATE dds.fact_production_plan_month
SET oil_plan_legacy = :'new_oil_plan'::numeric(24, 6)
WHERE well_id = :'well_id'::bigint
  AND month_start = :'month_start'::date
  AND scenario = :'scenario'
  AND oil_plan_legacy IS NOT DISTINCT FROM :'expected_oil_plan'::numeric(24, 6);

SELECT well_id, month_start, scenario, oil_plan_legacy
FROM dds.fact_production_plan_month
WHERE well_id = :'well_id'::bigint
  AND month_start = :'month_start'::date
  AND scenario = :'scenario';

-- Default to ROLLBACK for review. Replace with COMMIT only after inspecting
-- the result and deciding how the affected marts will be rebuilt.
ROLLBACK;
