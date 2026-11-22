# OilEnvelopeToStaging

SMT преобразует строковый JSON и Kafka-координаты в схему raw Iceberg-таблицы.

Исходный код: [OilEnvelopeToStaging.java](OilEnvelopeToStaging.java).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** GP и Iceberg connectors зарегистрированы как pipelines; Java-классы отдельно не каталогизированы.
- **Lakehouse:** GP sink остаётся исходным; отдельный Iceberg sink подготовлен и приостановлен.
