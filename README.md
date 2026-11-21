# Нефтегазовое DWH на Greenplum

Исходный контур двух отчётов: добыча по месторождениям и эффективность добычи с учётом простоев. 5 месторождений, 40 скважин, 2025 год; данные синтетические, масса в тоннах, время UTC. Первая цепочка уже перенесена в Lakehouse, вторая остаётся источником для показа миграции.

```text
Генератор → Kafka oil.events.v1 → GP Kafka Connect → oil_stg
                                                     ↓ Airflow oil_gp_release
                                              oil_dds → oil_mart → Superset
Kafka → отдельный Iceberg Connect → Lakehouse (второй репозиторий)
```

## Код

| Каталог | Назначение |
|---|---|
| `database/schemas/` | По одному файлу на схему STG, DDS и marts. |
| `database/oil_stg/` | Таблицы приёма, checkpoint, партии, разбор JSON и объединение партий. |
| `database/oil_dds/` | История событий, hubs, links, satellites и применение партии. |
| `database/oil_mart/` | Измерения, факты, агрегаты, два представления отчётов и расчётные функции. |
| `database/access/` | Права ограниченных сервисных ролей GP. |
| `airflow/oil_gp_release.py` | Source DAG: fence → apply batches → production → downtime → release fence. |
| `ingestion/oil_events.py` | Baseline и управляемая delta: исправление, replay, delete, late arrival, версия well. |
| `ingestion/contracts/` | JSON Schema события; это контракт, не выгрузка каталога и не Schema Registry. |
| `ingestion/gp-connect-src/` | Java sink: атомарная запись STG, batch и Kafka checkpoint в GP. |
| `ingestion/iceberg-smt-src/` | Преобразование события и Kafka координат в raw-строку Iceberg. |
| `ingestion/iceberg-auth-src/` | Обновление CIAM client-credentials токена для Iceberg REST. |
| `ingestion/wave2/` | Отдельный Connect worker, connector, Kafka fence, read-only панель наблюдения. |
| `superset/` | По одному декларативному JSON на dataset, chart и dashboard двух исходных отчётов. |
| `quality/` | Исполняемые SQL-проверки; результатов запусков в репозитории нет. |

## Сущности хранилища

| Сущность | За что отвечает |
|---|---|
| `oil_stg.event_log` | Исходный JSON и уникальная позиция topic/partition/offset. |
| `batch_control`, `kafka_checkpoint`, `kafka_batch_id_seq` | Статус партии, следующая доставляемая позиция, ID партии. |
| `event_reject`, `v_event_parsed` | Таблица для отклонённых записей; представление разбора JSON. Некорректная партия в apply откатывается целиком, автоматическая доставка в reject не заявляется. |
| `batch_coalesce_map`, `batch_coalesce_event_map`, `coalesce_ready_batches` | Контролируемое объединение READY партий с сохранением происхождения. |
| `oil_dds.event`, `apply_batch` | Реестр принятых событий; валидация, deduplication и проверка версий в одной транзакции. |
| `hub_field`, `hub_well`, `hub_production_day`, `hub_downtime` | Бизнес-ключи месторождения, скважины, скважино-дня и интервала простоя. |
| `link_well_field`, `link_production_day_well`, `link_downtime_well` | Связи скважины с месторождением, добычи и простоя со скважиной. |
| `sat_field`, `sat_well`, `sat_daily_production`, `sat_downtime` | Версии атрибутов и событий, включая удаления. |
| `dim_field`, `dim_well`, `dim_downtime_reason` | Исторические измерения и справочник причин простоя. |
| `fact_well_day`, `fact_downtime_interval` | Тонны по скважино-дню; интервалы и часы простоя. |
| `agg_field_day`, `agg_field_downtime_day` | Дневные агрегаты добычи и простоев по месторождению. |
| `refresh_production`, `refresh_downtime` | Пересчёт измерений/фактов/агрегатов; downtime выполняется после production. |
| `v_field_production`, `v_field_performance` | Serving-представления отчётов добычи и добычи с простоями. |
| `legacy_field_month_export_2024` | Отдельный учебный архив-кандидат на исключение, не участвует в двух цепочках. |

## Применение

`database/install.sql` — порядок установки через psql в **новую** БД с подготовленными service roles. Файлы сущностей не являются идемпотентными миграциями для работающей БД. Опциональный `database/create_legacy_candidate.sql` запускается после заполнения первой витрины. Для provisioning требуется `OIL_GP_SSH_CONFIG`; пароли и TLS-файлы находятся вне Git.

Baseline генератора: `--phase baseline --seed 42 --fields 5 --wells 40 --days 365`; delta: `--phase delta` с теми же параметрами. Для реальной отправки добавляется `--kafka`; повторный baseline в рабочий topic не отправлять. Ручной DAG `oil_gp_release` запускается с `{}` и обрабатывает максимум 100 READY партий.

Superset: dataset 4 / dashboard 3 — добыча; dataset 5 / dashboard 4 — простои. JSON содержит только определения, параметры графиков, фильтры и layout; ID относятся к этому стенду. Доступ к соединениям настраивается отдельно, credentials не включены.

Модель DDS использует Raw Vault patterns, marts — Kimball star. Kafka один broker/RF=1: это стенд с production-подобной логикой, не промышленная HA. Сопутствующий код: [dlh-scripts](https://github.com/ncuho/dlh-scripts).
