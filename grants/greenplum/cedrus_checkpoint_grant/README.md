# cedrus_checkpoint_grant

Назначает минимальные права чтения checkpoint при согласовании границы.

Исходный код: [cedrus_checkpoint_grant.sql](cedrus_checkpoint_grant.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Управляются нативными GP/Kafka/CIAM/LakeKeeper механизмами; отдельной карточки grant в Data Catalog нет.
- **Lakehouse:** GP GRANT не копируются буквально. Целевые CIAM-backed роли и LakeKeeper permissions настроены отдельно.
