# coalesce_ready_batches

Объединяет ограниченный диапазон READY-партий одного источника с сохранением происхождения. Работает под общей блокировкой writer.

Тип: хранимая функция PL/pgSQL Greenplum 6; это не процедура CALL.

Исходный код: [coalesce_ready_batches.sql](coalesce_ready_batches.sql).

## Статус сущности

- **GitHub:** код и описание находятся в этой папке.
- **Data Catalog:** Отдельной карточки функции нет; обработка отражена в описаниях DAG и lineage.
- **Lakehouse:** GP coalesce не копируется в Iceberg; нужен только исходному учёту партий.
