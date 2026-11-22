# batch_control

Хранит жизненный цикл партии: OPEN, READY, COALESCED, APPLIED или FAILED. Отделяет успешную доставку от применения в DDS.

Исходный код: [batch_control.sql](batch_control.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка таблицы в Data Catalog.
- **Lakehouse:** Техническая таблица GP не копируется; целевой контроль реализован Kafka Connect и release workflow.
