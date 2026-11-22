# event_log

Принимает исходные JSON-события вместе с topic, partition, offset и ID партии. Сохраняет доставку до применения бизнес-логики.

Исходный код: [event_log.sql](event_log.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка таблицы в Data Catalog.
- **Lakehouse:** Целевой экземпляр удалён; код подготовлен для новой миграции. Включены field/well/production_day; downtime в этот baseline не входит.
