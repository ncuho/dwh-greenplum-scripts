-- Разрешает исходному DAG проверять журнал и rejects перед фиксацией бизнес-расчёта.
GRANT SELECT ON oil_dds.event, oil_stg.event_reject TO demo_airflow_runner;


-- UPDATE на checkpoint необходим для стандартного LOCK TABLE IN EXCLUSIVE MODE; DAG не меняет offsets самостоятельно.
GRANT UPDATE ON oil_stg.kafka_checkpoint TO demo_airflow_runner;
