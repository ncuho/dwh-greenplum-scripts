# batch_coalesce_event_map

Сохраняет соответствие каждой Kafka-позиции исходной и объединённой партиям.

Исходный код: [batch_coalesce_event_map.sql](batch_coalesce_event_map.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка таблицы в Data Catalog.
- **Lakehouse:** Техническая таблица GP не копируется; целевой контроль реализован Kafka Connect и release workflow.
