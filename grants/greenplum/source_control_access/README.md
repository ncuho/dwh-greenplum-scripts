# source_control_access

Назначает минимальные права контроля статуса партий и checkpoints без прямой записи.

Исходный код: [source_control_access.sql](source_control_access.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Управляются нативными GP/Kafka/CIAM/LakeKeeper механизмами; отдельной карточки grant в Data Catalog нет.
- **Lakehouse:** GP GRANT не копируются буквально. Целевые CIAM-backed роли и LakeKeeper permissions настроены отдельно.
