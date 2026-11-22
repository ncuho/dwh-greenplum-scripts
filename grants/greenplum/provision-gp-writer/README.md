# provision-gp-writer

Создаёт ограниченного Kafka writer в GP и защищённый credential-файл. Требует явной SSH-конфигурации; не предназначен для повторного запуска вслепую.

Исходный код: [provision-gp-writer.py](provision-gp-writer.py).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Управляются нативными GP/Kafka/CIAM/LakeKeeper механизмами; отдельной карточки grant в Data Catalog нет.
- **Lakehouse:** GP GRANT не копируются буквально. Целевые CIAM-backed роли и LakeKeeper permissions настроены отдельно.
