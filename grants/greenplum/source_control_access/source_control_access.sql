-- Контекст миграции: AS IS / TO BE.
-- Назначение: Назначает минимальные права контроля статуса партий и checkpoints без прямой записи.
-- AS IS: Роли GP ограничивают чтение и запуск source-логики.
-- TO BE: CIAM задаёт identities/роли; LakeKeeper выдаёт права на target table UUID.
-- Отличие: GRANT GP не переносится буквально; Superset RBAC проверяется отдельно.
-- Конец контекста миграции.
-- Read-only technical counters for the bounded source and migration controllers.
-- No payload read or direct write is granted to the Airflow runner.
BEGIN;
GRANT USAGE ON SCHEMA oil_stg TO demo_airflow_runner;
GRANT SELECT ON oil_stg.batch_control, oil_stg.kafka_checkpoint TO demo_airflow_runner;
GRANT SELECT ON oil_stg.batch_control TO cedrus_gp_ro;
COMMIT;
