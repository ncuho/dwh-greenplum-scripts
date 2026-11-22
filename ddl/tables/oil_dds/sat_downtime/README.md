# sat_downtime

Сохраняет версии атрибутов интервала простоя, event_id, entity_version и операцию U/D. GP хранит типизированный payload и audit-поля; release DLH использует логическую проекцию с исходным document.

Исходный код: [sat_downtime.sql](sat_downtime.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка таблицы в Data Catalog.
- **Lakehouse:** Вторая цепочка: исходный объект работает в GP; целевой SQL подготовлен, постоянный release ещё не создан.
