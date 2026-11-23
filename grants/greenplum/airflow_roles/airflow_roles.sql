-- Назначение: Назначает минимальные права вызова SECURITY DEFINER расчётных функций и доступа их владельца.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
-- Explicit, narrowly scoped SECURITY DEFINER executor for manual GP releases.
-- The existing demo_airflow_runner login has no direct write access to these tables.
BEGIN;
CREATE ROLE oil_airflow_executor NOLOGIN;
GRANT USAGE ON SCHEMA oil_stg, oil_dds, oil_mart TO oil_airflow_executor;
GRANT SELECT ON oil_stg.v_event_parsed, oil_stg.batch_control TO oil_airflow_executor;
GRANT UPDATE ON oil_stg.batch_control TO oil_airflow_executor;
GRANT SELECT, INSERT ON oil_dds.event, oil_dds.hub_field, oil_dds.hub_well, oil_dds.hub_production_day, oil_dds.hub_downtime, oil_dds.link_well_field, oil_dds.link_production_day_well, oil_dds.link_downtime_well, oil_dds.sat_field, oil_dds.sat_well, oil_dds.sat_daily_production, oil_dds.sat_downtime TO oil_airflow_executor;
GRANT SELECT, INSERT, DELETE ON oil_mart.dim_field, oil_mart.dim_well, oil_mart.dim_downtime_reason, oil_mart.fact_well_day, oil_mart.fact_downtime_interval, oil_mart.agg_field_day, oil_mart.agg_field_downtime_day TO oil_airflow_executor;
REVOKE ALL ON FUNCTION oil_dds.apply_batch (bigint), oil_mart.refresh_production (), oil_mart.refresh_downtime () FROM PUBLIC;
ALTER FUNCTION oil_dds.apply_batch (bigint) SECURITY DEFINER;
ALTER FUNCTION oil_mart.refresh_production () SECURITY DEFINER;
ALTER FUNCTION oil_mart.refresh_downtime () SECURITY DEFINER;
ALTER FUNCTION oil_dds.apply_batch (bigint) SET search_path = pg_catalog, pg_temp;
ALTER FUNCTION oil_mart.refresh_production () SET search_path = pg_catalog, pg_temp;
ALTER FUNCTION oil_mart.refresh_downtime () SET search_path = pg_catalog, pg_temp;
ALTER FUNCTION oil_dds.apply_batch (bigint) OWNER TO oil_airflow_executor;
ALTER FUNCTION oil_mart.refresh_production () OWNER TO oil_airflow_executor;
ALTER FUNCTION oil_mart.refresh_downtime () OWNER TO oil_airflow_executor;
GRANT USAGE ON SCHEMA oil_dds, oil_mart TO demo_airflow_runner;
GRANT EXECUTE ON FUNCTION oil_dds.apply_batch (bigint), oil_mart.refresh_production (), oil_mart.refresh_downtime () TO demo_airflow_runner;
COMMIT;
