\set ON_ERROR_STOP on

-- Deterministic synthetic enrichment of the exact existing mirrors. New og_dwh only.
BEGIN;

SET statement_timeout='240s';

SET TIME ZONE 'UTC';

\ir ../../dml/bootstrap/ref/unit.sql

\ir ../../dml/bootstrap/ref/calendar.sql

\ir ../../dml/bootstrap/ref/product.sql

\ir ../../dml/bootstrap/ref/repair_type.sql

\ir ../../dml/bootstrap/ref/downtime_reason.sql

\ir ../../dml/bootstrap/ref/sensor_type.sql

\ir ../../dml/bootstrap/ref/energy_tariff.sql

\ir ../../dml/bootstrap/ref/quality_spec.sql

\ir ../../dml/bootstrap/ctl/load_batch.sql

\ir ../../dml/bootstrap/dds/dim_well_scd2.sql

\ir ../../dml/bootstrap/dds/dim_equipment.sql

\ir ../../dml/bootstrap/dds/bridge_equipment_well_history.sql

\ir ../../dml/bootstrap/dds/dim_contract.sql

\ir ../../dml/bootstrap/dds/fact_repair_order.sql

\ir ../../dml/bootstrap/dds/fact_downtime_interval.sql

\ir ../../dml/bootstrap/dds/fact_repair_operation.sql

\ir ../../dml/bootstrap/working/production_weights.sql

\ir ../../dml/bootstrap/working/production_floors.sql

\ir ../../dml/bootstrap/dds/fact_production_day.sql

\ir ../../dml/bootstrap/dds/fact_energy_day.sql

\ir ../../dml/bootstrap/dds/fact_telemetry_hour.sql

\ir ../../dml/bootstrap/dds/fact_production_plan_month.sql

\ir ../../dml/bootstrap/dds/fact_lab_sample.sql

\ir ../../dml/bootstrap/dds/fact_quality_measurement.sql

\ir ../../dml/bootstrap/dds/fact_shipment.sql

\ir ../../dml/bootstrap/dds/fact_shipment_item.sql

\ir ../../dml/bootstrap/stg/measurement_event.sql

\ir ../../dml/bootstrap/stg/repair_event.sql

\ir ../../dml/bootstrap/stg/lab_event.sql

\ir ../../dml/bootstrap/stg/shipment_event.sql

\ir ../../dml/bootstrap/ctl/load_batch__finalize.sql

COMMIT;
