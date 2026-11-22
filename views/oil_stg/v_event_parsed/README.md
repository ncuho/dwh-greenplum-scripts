# v_event_parsed

Разбирает envelope JSON в STG: тип, ID, версию, операцию, время и payload без изменения исходного документа.

Исходный код: [v_event_parsed.sql](v_event_parsed.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Зарегистрирована отдельная карточка представления в Data Catalog.
- **Lakehouse:** Разбор JSON реализован SQL canonicalization; отдельный такой view в DLH не создаётся.
