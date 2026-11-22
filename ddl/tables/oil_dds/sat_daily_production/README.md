# sat_daily_production

Сохраняет версии атрибутов дневной добычи, event_id, entity_version и операцию U/D. GP хранит типизированный payload и audit-поля; release DLH использует логическую проекцию с исходным document.

Исходный код: [sat_daily_production.sql](sat_daily_production.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка таблицы в Data Catalog.
- **Lakehouse:** Целевой экземпляр удалён; код подготовлен для новой миграции.
