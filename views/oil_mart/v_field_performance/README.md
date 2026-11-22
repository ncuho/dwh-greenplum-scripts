# v_field_performance

Serving-представление второй цепочки: LEFT JOIN дневной добычи с дневными простоями по дате и месторождению; отсутствие простоя даёт 0 часов.

Исходный код: [v_field_performance.sql](v_field_performance.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка представления в Data Catalog.
- **Lakehouse:** Подготовлена физическая field_performance нового release; до INITIAL/PUBLISH используется пустой буфер.
