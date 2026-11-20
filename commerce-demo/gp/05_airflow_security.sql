-- Apply as privileged administrator after creating LOGIN role demo_airflow_runner
-- and NOLOGIN role demo_airflow_executor with a secret manager or protected channel.
-- Source functions use schema-qualified objects, no dynamic SQL, and built-ins.
BEGIN;
GRANT USAGE ON SCHEMA demo_stg, demo_ods, demo_vault, demo_dm TO demo_airflow_executor;
GRANT SELECT ON demo_stg.v_event_parsed, demo_stg.batch_control TO demo_airflow_executor;
GRANT UPDATE ON demo_stg.batch_control TO demo_airflow_executor;
GRANT SELECT, INSERT ON demo_ods.event TO demo_airflow_executor;
GRANT SELECT, INSERT ON demo_vault.hub_product, demo_vault.hub_store, demo_vault.hub_shipment, demo_vault.hub_return, demo_vault.link_shipment, demo_vault.link_return, demo_vault.sat_product, demo_vault.sat_store, demo_vault.sat_shipment, demo_vault.sat_return TO demo_airflow_executor;
GRANT SELECT ON demo_vault.v_shipment_current, demo_vault.v_return_current TO demo_airflow_executor;
GRANT SELECT, INSERT, DELETE ON demo_dm.dim_product, demo_dm.dim_store, demo_dm.fact_shipment, demo_dm.fact_return, demo_dm.sales_day TO demo_airflow_executor;
REVOKE ALL ON FUNCTION demo_ods.apply_batch(bigint), demo_dm.rebuild() FROM PUBLIC;
ALTER FUNCTION demo_ods.apply_batch(bigint) SECURITY DEFINER;
ALTER FUNCTION demo_dm.rebuild() SECURITY DEFINER;
ALTER FUNCTION demo_ods.apply_batch(bigint) SET search_path = pg_catalog, pg_temp;
ALTER FUNCTION demo_dm.rebuild() SET search_path = pg_catalog, pg_temp;
ALTER FUNCTION demo_ods.apply_batch(bigint) OWNER TO demo_airflow_executor;
ALTER FUNCTION demo_dm.rebuild() OWNER TO demo_airflow_executor;
GRANT USAGE ON SCHEMA demo_ods, demo_dm TO demo_airflow_runner;
GRANT EXECUTE ON FUNCTION demo_ods.apply_batch(bigint), demo_dm.rebuild() TO demo_airflow_runner;
COMMIT;
