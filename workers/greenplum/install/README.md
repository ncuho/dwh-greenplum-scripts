# install

Устанавливает GP Connect worker и его служебные topics.

Исходный код: [install.sh](install.sh).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Назначение worker отражено pipeline service; отдельной карточки systemd unit нет.
- **Lakehouse:** Оба workers развёрнуты на Kafka VM, target worker обслуживает новое направление Iceberg.
