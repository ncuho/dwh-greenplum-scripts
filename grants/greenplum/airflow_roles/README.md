# airflow_roles

Назначает минимальные права вызова SECURITY DEFINER расчётных функций и доступа их владельца.

Исходный код: [airflow_roles.sql](airflow_roles.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Управляются нативными GP/Kafka/CIAM/LakeKeeper механизмами; отдельной карточки grant в Data Catalog нет.
- **Lakehouse:** GP GRANT не копируются буквально. Целевые CIAM-backed роли и LakeKeeper permissions настроены отдельно.
