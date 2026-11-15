# Как переносить эту модель в Lakehouse

Это карта конкретного учебного DWH. SQL-кандидаты целевого движка ещё не исполнялись. Изменение соединения само по себе не доказывает миграцию.

| Greenplum | Решение для Iceberg / движка | Что проверить |
|---|---|---|
| 46 исходных зеркал: heap, исходные DOUBLE и naive timestamps | Bronze сохраняет значения/NULL/типы; timestamp не получает новую timezone | Typed multiset parity; FLOAT64 по битам либо явно утверждённый контракт численной эквивалентности |
| HASH(well_id), RANDOM, REPLICATED | Не переводятся механически в bucket/partition | Объём, join workload, skew; небольшие dimensions могут остаться без partitioning |
| AO row / AOCO, zlib | Parquet и выбранная доступная компрессия | Реальные размеры, чтение и write interoperability; настройки кодека не переносятся 1:1 |
| Monthly RANGE + default partition | `month(business_date)` / `month(event_ts)` для выбранных фактов | Default в GP должен быть пуст; неожиданные даты quarantine/reject, не скрытая потеря |
| Partition EXCHANGE | Отдельная загрузка/commit/публикация Iceberg | Нет SQL-операции, тождественной многотабличной атомарности GP |
| Heap btree/bitmap | File pruning, stats, сортировка по workload | Индекс не копируется. ENUM не имеет bitmap operator class в установленном GP6 |
| PK/unique (где GP реально поддерживает) | Проверки ключей перед commit/release | Iceberg не начинает enforced PK/FK от объявления метаданных |
| `ref.tariff_rate` domain, `ref.work_state` enum | DECIMAL(12,6) и STRING + явная проверка допустимых значений | CHECK/domain/enum не должны молча исчезать |
| `ctl.run_id_seq` | Внешний run/release ID или проверенный генератор | `max(id)+1` не безопасен при конкурентных writers |
| `etl.f_parse_telemetry(json)` | Явное извлечение/CAST JSON в SQL либо Spark | Неверный тип — ошибка/quarantine, не превращение в NULL без следа |
| `etl.rebuild_production_day` | Set-based stages + явные guards + release state | Calendar UTC, SCD2 `[from,to)`, downtime overlap rejection, exact decimal residual |
| `etl.rebuild_marts` | Семь отдельных candidate writes и публикация версии набора | **В GP семь dm + audit заменяются одной caller transaction. В Iceberg один snapshot атомарен для одной таблицы. Общего COMMIT семи таблиц мы не обещаем.** |
| Temp tables и dynamic SQL | Промежуточные run-scoped stages, allowlisted identifiers | SQLGlot не доказывает procedural semantics или корректность побочных эффектов |
| Materialized view | Отдельный агрегат и проверенный refresh schedule | Native MV compatibility целевого каталога не предполагается |
| Resource queues | Изоляция workloads выбранного нового runtime | Исходные queues не равны автоматически target pools/groups |
| Views / grants | Новые datasets и явная карта доступа | Metadata catalogue tag не обеспечивает row policy; native GP6 RLS здесь не заявляется |

## Первая волна

Перенести в новый run-scoped Bronze как минимум: `ods.sng_tbl_locality`, `ods.sng_tbl_well`, `ods.sng_tbl_production_volume`, `ref.calendar`, `dds.dim_well_scd2`, `dds.fact_production_day`, `dds.fact_downtime_interval`, `dds.fact_energy_day`, `dds.fact_production_plan_month`. Пример именования target table — имя source schema и table через `_`; namespace задаётся утверждённым manifest. Исходные 46 таблиц DLH не являются площадкой для overwrite.

Согласовать frozen cut или иной доказанный согласованный срез GP. Несколько JDBC connections не получают единый snapshot автоматически. При ограниченной учебной остановке writers можно удержать SHARE locks ровно на source wave tables до extraction/readback; source DDL и активные ETL также должны быть учтены.

`migration/production-wave.cde.sql` строит два кандидата: daily balance и field-month performance. Он не переключает consumers. Перед применением заменить names через reviewed renderer, проверить отсутствие target names, выполнить orphan/key/SCD/range checks. Применять только в новом namespace; повтор CREATE после потерянного ответа требует reconciliation.

## Публикация и доказательства

Для run записать source table/version/code, row counts, quality results, target table UUID и snapshot IDs. Только после сверки полного набора создать запись `publication_release` со статусом VALIDATED; consumers должны читать одну выбранную release-версию всех таблиц. Управление release pointer выполняется во внешнем транзакционном control store или другим отдельно проверенным механизмом. Одна строка в независимой Iceberg control table сама по себе не создаёт distributed transaction.

Для нашего source сначала доказана атомарность и идемпотентность GP функции. Для target нужны независимые tests, отрицательный тест, проверка неполной публикации, query semantics, permissions и rollback условий. Source snapshot rollback и target-only writes не заменяют обратную синхронизацию.
