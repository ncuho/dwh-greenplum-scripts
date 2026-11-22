# enable-topic-authorizer

Включает авторизацию topic и scoped ACL. Сохраняет исходную конфигурацию и поддерживает возврат при ошибке.

Исходный код: [enable-topic-authorizer.sh](enable-topic-authorizer.sh).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Управляются нативными GP/Kafka/CIAM/LakeKeeper механизмами; отдельной карточки grant в Data Catalog нет.
- **Lakehouse:** GP GRANT не копируются буквально. Целевые CIAM-backed роли и LakeKeeper permissions настроены отдельно.
