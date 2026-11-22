# Нефтегазовое DWH · Greenplum

Исходный контур управленческих отчётов добычи и простоев. Путь данных: источник событий → Kafka → GP Connect → STG → DDS → Marts → Superset. Происхождение и границы использования показателей: [паспорт данных](DATA-PASSPORT.md).

| Каталог | Ответственность |
|---|---|
| `ddl/` | Схемы, таблицы и последовательность; одна сущность на SQL-файл. |
| `functions/` | Четыре хранимые PL/pgSQL-функции: apply, production refresh, downtime refresh и coalesce. |
| `views/` | Разбор envelope и два serving-представления отчётов. |
| `queries/` | Read-only песочница по слоям и SQL-проверки. |
| `dags/` | `oil_gp_release`: управляемое применение партий и расчёты. |
| `topics/` | Создание oil.events.v1 и контракт четырёх типов событий. |
| `generators/` | Источник baseline/delta и TLS wrapper. |
| `connectors/` | GP sink, Iceberg sink, SMT и CIAM AuthManager. |
| `workers/` | Конфигурация двух независимых Connect workers. |
| `grants/` | Минимальные GP-права и Kafka ACL. |
| `migration/` | Фиксация offsets и контроллер живой границы. |
| `monitoring/` | Read-only наблюдение за Kafka и connectors. |
| `superset/` | Отдельные datasets, charts, dashboards двух отчётов. |
| `deploy/` | Порядок создания объектов в новой БД. |

Рядом с каждым кодовым файлом находится одноимённый MD: назначение, поведение и роль в цепочке. В Greenplum 6 используются хранимые функции, нативных процедур CALL в этом решении нет.

STG сохраняет доставку и checkpoints. DDS использует Raw Vault patterns: event ledger, 4 hubs, 3 links и 4 satellites; полное соответствие стандарту Data Vault 2.0 не заявляется. Marts использует исторические измерения и факты Kimball; serving-агрегаты упрощают BI.

Первая цепочка: field/well/production_day → apply_batch → refresh_production → v_field_production → dashboard 3. Вторая добавляет downtime → refresh_downtime → v_field_performance → dashboard 4. Общие зависимости рассчитываются до простоев.

`deploy/install.sql` предназначен для новой БД с подготовленными service roles; повторный запуск поверх рабочих объектов не предусмотрен. Архивный экспорт создаётся отдельно после заполнения витрины. Baseline источника: seed 42, 5 fields, 40 wells, 365 days; повторная отправка baseline в рабочий topic не допускается. Секреты вне Git.

Kafka имеет один broker/RF=1. Идентификаторы установленных connections, групп, Java-классов и TLS-путей сохраняются ради совместимости. [Целевой контур DLH](https://github.com/ncuho/dlh-scripts).
