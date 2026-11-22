# event

Реестр принятых событий DDS. event_id определяет повтор, entity_version задаёт порядок изменений, event_document позволяет сверить историю.

Исходный код: [event.sql](event.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка таблицы в Data Catalog.
- **Lakehouse:** Целевой экземпляр удалён; код подготовлен для новой миграции. Включены field/well/production_day; downtime в этот baseline не входит.
