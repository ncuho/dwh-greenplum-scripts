# production

Dataset 4 читает oil_mart.v_field_production. Определяет временное поле, колонки и доступные метрики для графиков.

Исходный код: [production.json](production.json).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Отдельная карточка dataset не создавалась; источник отражён связью serving table → chart.
- **Lakehouse:** Исходный BI продолжает читать Greenplum. Целевые dataset/dashboard — отдельные объекты.
