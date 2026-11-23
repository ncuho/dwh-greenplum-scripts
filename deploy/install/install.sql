-- Контекст миграции: AS IS / TO BE.
-- Назначение: Задаёт порядок установки SQL-объектов через psql. Сервисные роли должны существовать; повторное применение к рабочим таблицам не предусмотрено.
-- AS IS: Разворачивает исходные GP-объекты либо отдельный legacy-кандидат.
-- TO BE: Целевой deploy создаёт только согласованные Iceberg-объекты своей волны.
-- Отличие: Этот deploy не является командой очистки DLH и не запускает целевую миграцию.
-- Конец контекста миграции.
-- Fresh database only; prerequisites: scoped service roles already exist.
\set ON_ERROR_STOP on
\ir ../../ddl/schemas/oil_stg/oil_stg.sql
\ir ../../ddl/schemas/oil_dds/oil_dds.sql
\ir ../../ddl/schemas/oil_mart/oil_mart.sql
\ir ../../ddl/tables/oil_stg/event_log/event_log.sql
\ir ../../ddl/tables/oil_stg/batch_control/batch_control.sql
\ir ../../ddl/tables/oil_stg/kafka_checkpoint/kafka_checkpoint.sql
\ir ../../ddl/tables/oil_stg/event_reject/event_reject.sql
\ir ../../ddl/tables/oil_dds/event/event.sql
\ir ../../ddl/tables/oil_dds/hub_field/hub_field.sql
\ir ../../ddl/tables/oil_dds/hub_well/hub_well.sql
\ir ../../ddl/tables/oil_dds/hub_production_day/hub_production_day.sql
\ir ../../ddl/tables/oil_dds/hub_downtime/hub_downtime.sql
\ir ../../ddl/tables/oil_dds/link_well_field/link_well_field.sql
\ir ../../ddl/tables/oil_dds/link_production_day_well/link_production_day_well.sql
\ir ../../ddl/tables/oil_dds/link_downtime_well/link_downtime_well.sql
\ir ../../ddl/tables/oil_dds/sat_field/sat_field.sql
\ir ../../ddl/tables/oil_dds/sat_well/sat_well.sql
\ir ../../ddl/tables/oil_dds/sat_daily_production/sat_daily_production.sql
\ir ../../ddl/tables/oil_dds/sat_downtime/sat_downtime.sql
\ir ../../ddl/tables/oil_mart/dim_field/dim_field.sql
\ir ../../ddl/tables/oil_mart/dim_well/dim_well.sql
\ir ../../ddl/tables/oil_mart/dim_downtime_reason/dim_downtime_reason.sql
\ir ../../ddl/tables/oil_mart/fact_well_day/fact_well_day.sql
\ir ../../ddl/tables/oil_mart/fact_downtime_interval/fact_downtime_interval.sql
\ir ../../ddl/tables/oil_mart/agg_field_day/agg_field_day.sql
\ir ../../ddl/tables/oil_mart/agg_field_downtime_day/agg_field_downtime_day.sql
\ir ../../views/oil_stg/v_event_parsed/v_event_parsed.sql
\ir ../../functions/oil_dds/apply_batch/apply_batch.sql
\ir ../../functions/oil_mart/refresh_production/refresh_production.sql
\ir ../../functions/oil_mart/refresh_downtime/refresh_downtime.sql
\ir ../../views/oil_mart/v_field_production/v_field_production.sql
\ir ../../views/oil_mart/v_field_performance/v_field_performance.sql
\ir ../../ddl/tables/oil_stg/batch_coalesce_map/batch_coalesce_map.sql
\ir ../../ddl/tables/oil_stg/batch_coalesce_event_map/batch_coalesce_event_map.sql
\ir ../../functions/oil_stg/coalesce_ready_batches/coalesce_ready_batches.sql
\ir ../../grants/greenplum/airflow_roles/airflow_roles.sql
\ir ../../grants/greenplum/cedrus_checkpoint_grant/cedrus_checkpoint_grant.sql
\ir ../../grants/greenplum/source_control_access/source_control_access.sql
\ir ../../ddl/sequences/oil_stg/kafka_batch_id_seq/kafka_batch_id_seq.sql
