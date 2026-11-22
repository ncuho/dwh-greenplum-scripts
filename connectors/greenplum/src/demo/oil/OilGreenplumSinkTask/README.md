# OilGreenplumSinkTask

Транзакционно записывает STG, партию и checkpoint. При старте продолжает от авторитетной позиции GP; ошибки offsets останавливают обработку.

Исходный код: [OilGreenplumSinkTask.java](OilGreenplumSinkTask.java).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** GP и Iceberg connectors зарегистрированы как pipelines; Java-классы отдельно не каталогизированы.
- **Lakehouse:** GP sink остаётся исходным; отдельный Iceberg sink подготовлен и приостановлен.
