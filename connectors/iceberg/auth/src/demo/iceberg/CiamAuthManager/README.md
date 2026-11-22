# CiamAuthManager

Обновляет client-credentials токен CIAM для Iceberg REST. Проверяет путь credential-файла, права файла и допустимый адрес LakeKeeper.

Исходный код: [CiamAuthManager.java](CiamAuthManager.java).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** GP и Iceberg connectors зарегистрированы как pipelines; Java-классы отдельно не каталогизированы.
- **Lakehouse:** GP sink остаётся исходным; отдельный Iceberg sink подготовлен и приостановлен.
