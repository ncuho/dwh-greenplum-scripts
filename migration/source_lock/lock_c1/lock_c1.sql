-- Открывает окно стабильного чтения GP; до запуска GP connector и расписание source DAG должны быть приостановлены.
BEGIN;


-- Ограничивает ожидание блокировки, а не длительность всего окна переноса.
SET LOCAL lock_timeout = '10s';


-- Ограничивает каждую команду в этой сессии; открытая транзакция сохраняется до явного COMMIT или ROLLBACK.
SET LOCAL statement_timeout = '180s';


-- Согласует окно с исходными функциями обработки; бизнес-данные здесь не изменяются.
SELECT pg_advisory_xact_lock(860223191::bigint);


-- SHARE разрешает обычный SELECT и задерживает INSERT, UPDATE, DELETE и конфликтующий DDL на исходных таблицах.
LOCK TABLE
    oil_dds.event,
    oil_dds.hub_downtime,
    oil_dds.hub_field,
    oil_dds.hub_production_day,
    oil_dds.hub_well,
    oil_dds.link_downtime_well,
    oil_dds.link_production_day_well,
    oil_dds.link_well_field,
    oil_dds.sat_daily_production,
    oil_dds.sat_downtime,
    oil_dds.sat_field,
    oil_dds.sat_well,
    oil_mart.agg_field_day,
    oil_mart.agg_field_downtime_day,
    oil_mart.dim_downtime_reason,
    oil_mart.dim_field,
    oil_mart.dim_well,
    oil_mart.fact_downtime_interval,
    oil_mart.fact_well_day,
    oil_mart.legacy_field_month_export_2024,
    oil_stg.batch_coalesce_event_map,
    oil_stg.batch_coalesce_map,
    oil_stg.batch_control,
    oil_stg.event_log,
    oil_stg.event_reject,
    oil_stg.kafka_checkpoint
IN SHARE MODE;


-- Удерживает определения двух переносимых view от изменения DDL до конца этого же окна.
SELECT 1 FROM oil_stg.v_event_parsed LIMIT 0;


-- Удерживает определение исходного serving view; таблицы под ним уже защищены SHARE-lock.
SELECT 1 FROM oil_mart.v_field_production LIMIT 0;


\pset format unaligned
\pset tuples_only on
-- Печатает готовый JSON для Trigger DAG; PID вместе с virtualtransaction определяет именно эту открытую транзакцию.
SELECT json_build_object(
    'mode', 'refresh',
    'source_lock', json_build_object(
        'pid', pg_backend_pid(),
        'database_oid', (SELECT oid::bigint FROM pg_database WHERE datname = current_database()),
        'virtualtransaction', virtualtransaction
    )
)
FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'virtualxid' AND granted
LIMIT 1;


-- Показывает применённую границу C1: next_offset — первая ещё не включённая позиция каждой Kafka-партиции.
SELECT topic, kafka_partition, next_offset
FROM oil_stg.kafka_checkpoint
WHERE topic = 'oil.events.v1'
ORDER BY kafka_partition;


-- Не закрывайте psql и не выполняйте COMMIT/ROLLBACK до завершения загрузки и сверок соответствующего выпуска.
