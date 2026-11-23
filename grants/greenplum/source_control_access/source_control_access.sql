-- Открывает транзакцию согласованного исходного среза.
BEGIN;


-- Выдаёт USAGE на SCHEMA oil_stg роли demo_airflow_runner.
GRANT USAGE ON SCHEMA oil_stg TO demo_airflow_runner;


-- Выдаёт SELECT на oil_stg.batch_control, oil_stg.kafka_checkpoint роли demo_airflow_runner.
GRANT SELECT ON oil_stg.batch_control, oil_stg.kafka_checkpoint TO demo_airflow_runner;


-- Выдаёт SELECT на oil_stg.batch_control роли cedrus_gp_ro.
GRANT SELECT ON oil_stg.batch_control TO cedrus_gp_ro;


-- Фиксирует исходный срез и освобождает блокировки GP.
COMMIT;


-- Разрешает исходному DAG сверять карты объединения партий с доставленными событиями до фиксации транзакции.
GRANT SELECT ON oil_stg.batch_coalesce_event_map, oil_stg.batch_coalesce_map, oil_stg.event_log TO demo_airflow_runner;
