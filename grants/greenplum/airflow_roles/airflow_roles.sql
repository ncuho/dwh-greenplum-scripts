-- Открывает транзакцию согласованного исходного среза.
BEGIN;


-- Создаёт роль oil_airflow_executor без отдельного входа для выполнения согласованных функций обработки.
CREATE ROLE oil_airflow_executor NOLOGIN;


-- Выдаёт USAGE на SCHEMA oil_stg, oil_dds, oil_mart роли oil_airflow_executor.
GRANT USAGE ON SCHEMA oil_stg, oil_dds, oil_mart TO oil_airflow_executor;


-- Выдаёт SELECT на oil_stg.v_event_parsed, oil_stg.batch_control роли oil_airflow_executor.
GRANT SELECT ON oil_stg.v_event_parsed, oil_stg.batch_control TO oil_airflow_executor;


-- Выдаёт UPDATE на oil_stg.batch_control роли oil_airflow_executor.
GRANT UPDATE ON oil_stg.batch_control TO oil_airflow_executor;


-- Выдаёт SELECT, INSERT на oil_dds.event, oil_dds.hub_field, oil_dds.hub_well, oil_dds.hub_production_day, oil_dds.hub_downtime, oil_dds.link_well_field, oil_dds.link_production_day_well, oil_dds.link_downtime_well, oil_dds.sat_field, oil_dds.sat_well, oil_dds.sat_daily_production, oil_dds.sat_downtime роли oil_airflow_executor.
GRANT SELECT, INSERT ON oil_dds.event, oil_dds.hub_field, oil_dds.hub_well, oil_dds.hub_production_day, oil_dds.hub_downtime, oil_dds.link_well_field, oil_dds.link_production_day_well, oil_dds.link_downtime_well, oil_dds.sat_field, oil_dds.sat_well, oil_dds.sat_daily_production, oil_dds.sat_downtime TO oil_airflow_executor;


-- Выдаёт SELECT, INSERT, DELETE на oil_mart.dim_field, oil_mart.dim_well, oil_mart.dim_downtime_reason, oil_mart.fact_well_day, oil_mart.fact_downtime_interval, oil_mart.agg_field_day, oil_mart.agg_field_downtime_day роли oil_airflow_executor.
GRANT SELECT, INSERT, DELETE ON oil_mart.dim_field, oil_mart.dim_well, oil_mart.dim_downtime_reason, oil_mart.fact_well_day, oil_mart.fact_downtime_interval, oil_mart.agg_field_day, oil_mart.agg_field_downtime_day TO oil_airflow_executor;


-- Отзывает явно перечисленные права у PUBLIC для ограничения доступа к объектам.
REVOKE ALL ON FUNCTION oil_dds.apply_batch (bigint), oil_mart.refresh_production (), oil_mart.refresh_downtime () FROM PUBLIC;


-- Включает выполнение oil_dds.apply_batch с правами владельца, чтобы сервисный пользователь вызывал функцию без прямой записи в таблицы.
ALTER FUNCTION oil_dds.apply_batch (bigint) SECURITY DEFINER;


-- Включает выполнение oil_mart.refresh_production с правами владельца, чтобы сервисный пользователь вызывал функцию без прямой записи в таблицы.
ALTER FUNCTION oil_mart.refresh_production () SECURITY DEFINER;


-- Включает выполнение oil_mart.refresh_downtime с правами владельца, чтобы сервисный пользователь вызывал функцию без прямой записи в таблицы.
ALTER FUNCTION oil_mart.refresh_downtime () SECURITY DEFINER;


-- Закрепляет безопасный search_path для oil_dds.apply_batch, исключая подмену объектов через пользовательские схемы.
ALTER FUNCTION oil_dds.apply_batch (bigint) SET search_path = pg_catalog, pg_temp;


-- Закрепляет безопасный search_path для oil_mart.refresh_production, исключая подмену объектов через пользовательские схемы.
ALTER FUNCTION oil_mart.refresh_production () SET search_path = pg_catalog, pg_temp;


-- Закрепляет безопасный search_path для oil_mart.refresh_downtime, исключая подмену объектов через пользовательские схемы.
ALTER FUNCTION oil_mart.refresh_downtime () SET search_path = pg_catalog, pg_temp;


-- Назначает владельца функции oil_dds.apply_batch с ограниченным набором прав обработки DWH.
ALTER FUNCTION oil_dds.apply_batch (bigint) OWNER TO oil_airflow_executor;


-- Назначает владельца функции oil_mart.refresh_production с ограниченным набором прав обработки DWH.
ALTER FUNCTION oil_mart.refresh_production () OWNER TO oil_airflow_executor;


-- Назначает владельца функции oil_mart.refresh_downtime с ограниченным набором прав обработки DWH.
ALTER FUNCTION oil_mart.refresh_downtime () OWNER TO oil_airflow_executor;


-- Выдаёт USAGE на SCHEMA oil_dds, oil_mart роли demo_airflow_runner.
GRANT USAGE ON SCHEMA oil_dds, oil_mart TO demo_airflow_runner;


-- Выдаёт EXECUTE на FUNCTION oil_dds.apply_batch (bigint), oil_mart.refresh_production (), oil_mart.refresh_downtime () роли demo_airflow_runner.
GRANT EXECUTE ON FUNCTION oil_dds.apply_batch (bigint), oil_mart.refresh_production (), oil_mart.refresh_downtime () TO demo_airflow_runner;


-- Фиксирует исходный срез и освобождает блокировки GP.
COMMIT;
