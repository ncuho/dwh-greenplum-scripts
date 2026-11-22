# kafka_checkpoint

Хранит следующий ожидаемый offset каждой партиции. Обновляется в одной транзакции с записью события в GP.

Исходный код: [kafka_checkpoint.sql](kafka_checkpoint.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка таблицы в Data Catalog.
- **Lakehouse:** Техническая таблица GP не копируется; целевой контроль реализован Kafka Connect и release workflow.
