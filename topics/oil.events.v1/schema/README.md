# schema

Определяет envelope и четыре типа payload нефтегазового события. Контракт хранится как код; Schema Registry enforcement отдельно не настроен.

Исходный код: [schema.json](schema.json).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирован business topic oil.events.v1; JSON Schema документирует контракт.
- **Lakehouse:** Topic общий для обоих consumers; topic и сообщения не перемещаются в другой Kafka.
