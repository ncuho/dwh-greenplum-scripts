# create

Создаёт topic oil.events.v1 с тремя партициями и retention 30 суток.

Исходный код: [create.sh](create.sh).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирован business topic oil.events.v1; JSON Schema документирует контракт.
- **Lakehouse:** Topic общий для обоих consumers; topic и сообщения не перемещаются в другой Kafka.
