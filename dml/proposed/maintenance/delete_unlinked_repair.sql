-- Prepared, not executed. Guards cover only two known dependent tables.
-- Other consumers, lineage, permissions and concurrent inserts need review.
\set ON_ERROR_STOP on
BEGIN;
DELETE FROM dds.fact_repair_order AS repair
WHERE repair.well_id = :'well_id'::bigint
  AND repair.repair_order_id = :'repair_order_id'::bigint
  AND NOT EXISTS (
      SELECT 1 FROM dds.fact_repair_operation AS operation
      WHERE operation.well_id = repair.well_id
        AND operation.repair_order_id = repair.repair_order_id
  )
  AND NOT EXISTS (
      SELECT 1 FROM dds.fact_downtime_interval AS downtime
      WHERE downtime.well_id = repair.well_id
        AND downtime.repair_order_id = repair.repair_order_id
  )
RETURNING well_id, repair_order_id;
ROLLBACK;
