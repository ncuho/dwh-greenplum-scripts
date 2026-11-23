-- Контекст миграции: AS IS / TO BE.
-- Назначение: Назначает минимальные права чтения checkpoint при согласовании границы.
-- AS IS: Роли GP ограничивают чтение и запуск source-логики.
-- TO BE: CIAM задаёт identities/роли; LakeKeeper выдаёт права на target table UUID.
-- Отличие: GRANT GP не переносится буквально; Superset RBAC проверяется отдельно.
-- Конец контекста миграции.
-- Read-only visibility required to compare GP exclusive checkpoints with Kafka.
-- Assumes cedrus_gp_ro and USAGE on oil_stg are already managed by the platform.
GRANT SELECT ON oil_stg.kafka_checkpoint TO cedrus_gp_ro;
