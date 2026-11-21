-- Read-only technical counters for the bounded source and migration controllers.
-- No payload read or direct write is granted to the Airflow runner.
BEGIN;
GRANT USAGE ON SCHEMA oil_stg TO demo_airflow_runner;
GRANT SELECT ON oil_stg.batch_control, oil_stg.kafka_checkpoint TO demo_airflow_runner;
GRANT SELECT ON oil_stg.batch_control TO cedrus_gp_ro;
COMMIT;
