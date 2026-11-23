# OilEnvelopeToStaging

SMT преобразует строковый JSON и Kafka-координаты в схему raw Iceberg-таблицы.

Исходный код: [OilEnvelopeToStaging.java](OilEnvelopeToStaging.java).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** GP и Iceberg connectors зарегистрированы как pipelines; Java-классы отдельно не каталогизированы.
- **Lakehouse:** GP sink остаётся исходным; отдельный Iceberg sink подготовлен и приостановлен.

## Контракт доставки

Установленный SMT проверяет ровно один `allowed.topic`, envelope/schema_version, event_id, entity key/version, op и исходный JSON. Topic переопределяется вместе с конфигурацией connector, чтобы новая цепочка не была привязана к чужому topic. `event_json` сохраняется без пересериализации.

`batch_id = (partition << 56) | offset` — технический идентификатор доставки, он не равен GP batch sequence. `received_at` обязателен и заполняется фактическими часами приёма в SMT (`java.util.Date`); при Kafka replay он может измениться. Business event_time берётся из JSON. Отсутствие audit времени блокируется DQ.

Класс скомпилирован и проверен JVM-контрактом: JSON сохранён, координаты стабильны, timestamp присутствует и лежит между началом и концом обработки. Перезапускался только целевой Iceberg worker; GP worker не перезапускался.
