# DWH на Greenplum

[Архитектура со слоями и моделями](architecture/README.md). Комментарии SQL/Python поясняют назначение и бизнес-логику. Native SQL окон C0/C1 находится в [migration/source_lock](migration/source_lock); source DAG вызывает бизнес-функции напрямую.


## Текущее состояние

Greenplum — работающий исходный контур. Подготовлены 20 пустых целевых объектов в Bronze/Silver/Gold; независимый Iceberg sink пишет raw. Исходные dashboards 3 и 4 сохранены. Текущий маршрут переносит первую цепочку прямым чтением GP под стандартными SHARE-lock. GP ingestion приостанавливается только на окна загрузки и сверок; Kafka и Iceberg sink продолжают работу.

## Данные и три слоя Greenplum

Один поток `oil.events.v1` содержит четыре типа событий: месторождение, скважина, суточная добыча, простой. Исходный набор: 5 месторождений, 40 скважин, 365 дат 2025 года. Добыча хранится в decimal, время — UTC.

- **Stage / oil_stg:** исходный JSON, координаты Kafka, партии, checkpoints, rejects и аудит объединения партий. Приём сообщения ещё не означает его применение в DDS.
- **DDS / oil_dds:** event ledger, hubs ключей, links отношений, satellites версий. Используются паттерны DV2 и аудит загрузки; полная enterprise-реализация всех практик Data Vault 2.0 не заявляется.
- **Marts / oil_mart:** исторические SCD2-измерения, факт скважино-дня, факт интервала простоя, дневные агрегаты и serving views. Это связанные размерные модели с общими измерениями; не произвольное объединение таблиц и не строгая отдельная snowflake-модель.

Продуктивность = SUM(oil_tonnes) / NULLIF(SUM(producing_well_days), 0). Это тонны на активный скважино-день, а не тонны на уникальную скважину за весь период. Факт присоединяется к действовавшей версии измерения, а не к текущему названию/статусу.

## Две цепочки и общие зависимости

```text
generator → Kafka oil.events.v1 → GP sink
  → Stage event_log / batch_control / checkpoint
  → apply_batch → DDS event + hubs / links / satellites
  → refresh_production → dim_field / dim_well
  → fact_well_day → agg_field_day → v_field_production
  → Superset dataset 4 / dashboard 3

та же история + downtime
  → hub_downtime / link_downtime_well / sat_downtime
  → refresh_downtime (после refresh_production)
  → dim_downtime_reason / fact_downtime_interval
  → agg_field_downtime_day + agg_field_day → v_field_performance
  → Superset dataset 5 / dashboard 4
```

Это один источник и два бизнес-отчёта. Stage, apply_batch, производственные измерения/факты и source DAG `oil_gp_release` общие. Изменение добычи или скважины может изменить оба исходных отчёта; изменение простоя — ветку эффективности. Source DAG применяет партии и последовательно вызывает обе функции расчёта.

Целевой Spark SQL переиспользуется как код. Физические baseline/releases двух волн по умолчанию отдельные; публикация одной не переключает другую. Переиспользование общих физических target-измерений требует отдельного согласованного snapshot-контракта.

## Целевая архитектура со Spark

```text
исходные таблицы GP под SHARE-lock → Cedrus → Iceberg INITIAL
Kafka → отдельный Iceberg sink → Iceberg raw JSON + offsets
pinned INITIAL + накопительная дельта → Spark → новый Iceberg release
release → Cedrus → отдельный Superset dataset / dashboard
Airflow: порядок и logs; LakeKeeper + CIAM: доступ; Catalog: описания и lineage
```

Cedrus извлекает историю и выполняет межконтурные сверки. Spark выполняет версии, SCD2, факты и агрегаты. JupyterHub нужен для явного просмотра/исполнения кода; Airflow запускает отдельную Spark-сессию через выделенный MCP/Spark Connect. Исторический Cedrus-only код сохранён, но выбранный новый маршрут бизнес-расчётов — Spark.

Текущий layered-маршрут сохраняет исходные имена и аудиторские поля выбранных объектов. В цели физические схемы Bronze/Silver/Gold; две исходные view материализуются. GP DISTRIBUTED BY, индексы, sequence, технические batch IDs и PL/pgSQL runtime не копируются в Iceberg буквально. Их смысл заменяют файловая организация, отдельные compute engines, offsets, snapshots, DAG и DQ.

## Граница, изменения и публикация

1. Отдельный Iceberg sink пишет `bronze.__raw_events`; producer продолжает отправлять версии до начала переноса.
2. На окно C0 оператор приостанавливает GP sink и расписание source DAG, ждёт текущие runs и завершает READY-партии одним ручным source run. Изменения этого run фиксируются до открытия окна чтения.
3. В административном psql открывается обычная транзакция с SHARE-блокировками исходных таблиц. Cedrus читает исходные `oil_stg/oil_dds/oil_mart` напрямую; служебные копии и реестр срезов не используются. Применённые Kafka offsets и token транзакции фиксируются в target receipt.
4. `oil_layered_migration` выполняет 14 Cedrus и 6 Spark операций INITIAL, 60 проверок, контроль snapshot и действительности исходных locks. При потере исходной транзакции READY запрещён.
5. Оператор повторяет сверки, выполняет COMMIT исходной транзакции, Resume GP connector и включает source DAG. Чтение отчёта GP доступно всё окно, но обновления обеих исходных веток в это время приостановлены.
6. После READY настраиваются LakeKeeper/CIAM доступы, отдельная BI-панель и фактический Catalog lineage исходные таблицы → обработка → цель → отчёт.
7. Для C1 повторяется окно pause/drain/SHARE-lock. REFRESH использует закреплённый INITIAL плюс полное raw-окно C0–C1 с дополнительным перекрытием до десяти offsets перед C0 по партициям. Stage дедуплицирует координаты, DDS — event_id, бизнес-версии определяются entity_version.
8. Пять Cedrus и пятнадцать Spark операций строят `_next` в Bronze/Silver/Gold. После 53 сверок оператор освобождает locks и возобновляет источник, затем отдельно переключает целевой отчёт. Исходный GP dashboard сохраняется.
9. Source-зависимые SQL-проверки воспроизводятся только пока удерживается соответствующее окно; после COMMIT сохраняются фактические результаты и target snapshots. Для новой живой сверки нужна новая граница.

Это плановое окно приостановки записи GP, а не полностью online-перенос без задержки. Действующий Cedrus GP connector поддерживает READ COMMITTED; независимые чтения получают стабильный источник благодаря стандартным блокировкам. Общей транзакции GP и Iceberg нет. Target-компенсация очищает только подтверждённые записи кандидата; неизвестный исход требует сверки. Произвольные изменения GP вне Kafka требуют CDC или отдельного согласованного механизма.

Kafka здесь доставляет события приложения; это не WAL CDC Greenplum. PXF/external tables не участвуют в исполняемой цепочке и не добавляются искусственно. Для такой дополнительной зависимости сначала нужны реальный внешний источник, контракт доступа и отдельная стратегия переноса.

## Доступы и ответственность сервисов

| Сервис | За что отвечает |
|---|---|
| GP | Исходные приём, история, функции и транзакционные расчёты |
| Kafka / Connect | Producer → topic; отдельные GP и Iceberg consumers и offset stores |
| Airflow | Порядок выполнения, run IDs и журнал; не заменяет общую транзакцию Iceberg |
| Spark | Целевые преобразования и материализация бизнес-слоёв |
| Cedrus | Чтение GP/Iceberg, историческая загрузка, сверка и SQL для BI |
| LakeKeeper | Iceberg REST catalog и permissions на реальные table UUID |
| CIAM | Идентичности людей/сервисов и роли |
| S3 / Iceberg | Файлы, metadata, snapshots и отдельно подтверждённые releases |
| Superset | Dataset, charts, dashboard и собственный BI RBAC |
| Data Catalog | Реальные сущности, описания, owners и сквозной lineage |
| GitHub | Версионируемый код; не хранилище secrets/runtime evidence |

Инженеру нужен create/write scope; sink получает MODIFY raw; reader — SELECT serving. Старый GRANT GP не превращается автоматически в LakeKeeper assignment. При новой таблице возникает новый UUID и проверяется новое разрешение. В BI отдельно проверяются пользовательская роль и identity SQL-соединения: end-user passthrough не подразумевается.

## Организация кода

Каждая сущность — отдельная папка с кодом и README. Не меняйте технические ID connector/consumer group без переноса offsets и прав. Credentials и runtime manifests хранятся вне Git.

## Полный указатель сущностей

Ссылки ведут в папки с автоматически открывающимся описанием; служебные реализации не обозначены как перенесённые бизнес-таблицы.

| Сущность | Назначение |
|---|---|
| [connectors/greenplum/connector](connectors/greenplum/connector/) | Конфигурация GP sink: Kafka → STG с транзакционным checkpoint. |
| [connectors/greenplum/src/demo/oil/OilGreenplumSinkConnector](connectors/greenplum/src/demo/oil/OilGreenplumSinkConnector/) | Объявляет и валидирует конфигурацию однотаскового Kafka Connect sink в Greenplum. |
| [connectors/greenplum/src/demo/oil/OilGreenplumSinkTask](connectors/greenplum/src/demo/oil/OilGreenplumSinkTask/) | Транзакционно записывает STG, партию и checkpoint. При старте продолжает от авторитетной позиции GP; ошибки offsets останавливают обработку. |
| [connectors/iceberg/auth/src/demo/iceberg/CiamAuthManager](connectors/iceberg/auth/src/demo/iceberg/CiamAuthManager/) | Обновляет client-credentials токен CIAM для Iceberg REST. Проверяет путь credential-файла, права файла и допустимый адрес LakeKeeper. |
| [connectors/iceberg/connector](connectors/iceberg/connector/) | Конфигурация Iceberg sink: Kafka → event_log_wave2, SMT и CIAM REST authentication. Первоначально создаётся остановленным. |
| [connectors/iceberg/transform/src/demo/oil/OilEnvelopeToStaging](connectors/iceberg/transform/src/demo/oil/OilEnvelopeToStaging/) | SMT преобразует строковый JSON и Kafka-координаты в схему raw Iceberg-таблицы. |
| [dags/oil_gp_release](dags/oil_gp_release/) | Управляемое применение партий и пересчёт двух цепочек Greenplum. Код: oil_gp_release.py. |
| [ddl/schemas/oil_dds](ddl/schemas/oil_dds/) | Схема интеграции и истории бизнес-сущностей с hubs, links и satellites. |
| [ddl/schemas/oil_mart](ddl/schemas/oil_mart/) | Схема измерений, фактов и serving-агрегатов управленческой отчётности. |
| [ddl/schemas/oil_stg](ddl/schemas/oil_stg/) | Схема приёма неизменённых событий и технического контроля загрузки. |
| [ddl/sequences/oil_stg/kafka_batch_id_seq](ddl/sequences/oil_stg/kafka_batch_id_seq/) | Выдаёт уникальные ID партий единственному Kafka writer. |
| [ddl/tables/oil_dds/event](ddl/tables/oil_dds/event/) | Реестр принятых событий DDS. event_id определяет повтор, entity_version задаёт порядок изменений, event_document позволяет сверить историю. |
| [ddl/tables/oil_dds/hub_downtime](ddl/tables/oil_dds/hub_downtime/) | Хранит бизнес-идентификатор интервала простоя и детерминированный hash key. Не содержит изменяемых описательных атрибутов. |
| [ddl/tables/oil_dds/hub_field](ddl/tables/oil_dds/hub_field/) | Хранит бизнес-идентификатор месторождения и детерминированный hash key. Не содержит изменяемых описательных атрибутов. |
| [ddl/tables/oil_dds/hub_production_day](ddl/tables/oil_dds/hub_production_day/) | Хранит бизнес-идентификатор скважино-дня добычи и детерминированный hash key. Не содержит изменяемых описательных атрибутов. |
| [ddl/tables/oil_dds/hub_well](ddl/tables/oil_dds/hub_well/) | Хранит бизнес-идентификатор скважины и детерминированный hash key. Не содержит изменяемых описательных атрибутов. |
| [ddl/tables/oil_dds/link_downtime_well](ddl/tables/oil_dds/link_downtime_well/) | Хранит историческую связь интервала простоя со скважиной по техническим ключам. Изменяемые атрибуты находятся в satellites. |
| [ddl/tables/oil_dds/link_production_day_well](ddl/tables/oil_dds/link_production_day_well/) | Хранит историческую связь скважино-дня со скважиной по техническим ключам. Изменяемые атрибуты находятся в satellites. |
| [ddl/tables/oil_dds/link_well_field](ddl/tables/oil_dds/link_well_field/) | Хранит историческую связь скважины с месторождением по техническим ключам. Изменяемые атрибуты находятся в satellites. |
| [ddl/tables/oil_dds/sat_daily_production](ddl/tables/oil_dds/sat_daily_production/) | Сохраняет версии атрибутов дневной добычи, event_id, entity_version и операцию U/D. GP хранит типизированный payload и audit-поля; release DLH использует логическую проекцию с исходным document. |
| [ddl/tables/oil_dds/sat_downtime](ddl/tables/oil_dds/sat_downtime/) | Сохраняет версии атрибутов интервала простоя, event_id, entity_version и операцию U/D. GP хранит типизированный payload и audit-поля; release DLH использует логическую проекцию с исходным document. |
| [ddl/tables/oil_dds/sat_field](ddl/tables/oil_dds/sat_field/) | Сохраняет версии атрибутов месторождения, event_id, entity_version и операцию U/D. GP хранит типизированный payload и audit-поля; release DLH использует логическую проекцию с исходным document. |
| [ddl/tables/oil_dds/sat_well](ddl/tables/oil_dds/sat_well/) | Сохраняет версии атрибутов скважины, event_id, entity_version и операцию U/D. GP хранит типизированный payload и audit-поля; release DLH использует логическую проекцию с исходным document. |
| [ddl/tables/oil_mart/agg_field_day](ddl/tables/oil_mart/agg_field_day/) | Дневная витрина зерна «месторождение × дата»: тонны, активные скважино-дни и тонны на активный скважино-день. |
| [ddl/tables/oil_mart/agg_field_downtime_day](ddl/tables/oil_mart/agg_field_downtime_day/) | Дневная сумма часов допустимых непересекающихся простоев по месторождению. |
| [ddl/tables/oil_mart/dim_downtime_reason](ddl/tables/oil_mart/dim_downtime_reason/) | Справочник причин: EQUIPMENT, POWER, PLANNED. Нормализует группировку простоев. |
| [ddl/tables/oil_mart/dim_field](ddl/tables/oil_mart/dim_field/) | Историческое измерение месторождения. Интервал действия версии — [valid_from, valid_to); удаление сохраняется отдельным признаком. |
| [ddl/tables/oil_mart/dim_well](ddl/tables/oil_mart/dim_well/) | Историческое измерение скважины, её принадлежности месторождению и статуса. Версия выбирается на производственную дату. |
| [ddl/tables/oil_mart/fact_downtime_interval](ddl/tables/oil_mart/fact_downtime_interval/) | Факт зерна «интервал простоя». Содержит скважину, месторождение, начало/конец, причину и длительность в часах. |
| [ddl/tables/oil_mart/fact_well_day](ddl/tables/oil_mart/fact_well_day/) | Факт зерна «скважина × производственная дата». Содержит тонны, статус и версии измерений well/field, действовавшие на дату. |
| [ddl/tables/oil_mart/legacy_field_month_export_2024](ddl/tables/oil_mart/legacy_field_month_export_2024/) | Архивный месячный экспорт, исключённый из обеих волн. Значения получены из baseline 2025 с коэффициентом 0.95 и сдвигом дат на год; они не подтверждают фактическую добычу 2024 года. Плановый потребитель не настроен. |
| [ddl/tables/oil_stg/batch_coalesce_event_map](ddl/tables/oil_stg/batch_coalesce_event_map/) | Сохраняет соответствие каждой Kafka-позиции исходной и объединённой партиям. |
| [ddl/tables/oil_stg/batch_coalesce_map](ddl/tables/oil_stg/batch_coalesce_map/) | Связывает исходные партии с объединённой партией и сохраняет число исходных доставок. |
| [ddl/tables/oil_stg/batch_control](ddl/tables/oil_stg/batch_control/) | Хранит жизненный цикл партии: OPEN, READY, COALESCED, APPLIED или FAILED. Отделяет успешную доставку от применения в DDS. |
| [ddl/tables/oil_stg/event_log](ddl/tables/oil_stg/event_log/) | Принимает исходные JSON-события вместе с topic, partition, offset и ID партии. Сохраняет доставку до применения бизнес-логики. |
| [ddl/tables/oil_stg/event_reject](ddl/tables/oil_stg/event_reject/) | Структура регистрации отклонённых событий. Автоматическое заполнение при ошибке apply не включено: некорректная партия откатывается. |
| [ddl/tables/oil_stg/kafka_checkpoint](ddl/tables/oil_stg/kafka_checkpoint/) | Хранит следующий ожидаемый offset каждой партиции. Обновляется в одной транзакции с записью события в GP. |
| [deploy/create_legacy_candidate](deploy/create_legacy_candidate/) | Отдельно создаёт архивный экспорт после заполнения дневной витрины; в основную установку и активные цепочки не входит. |
| [deploy/install](deploy/install/) | Задаёт порядок установки SQL-объектов через psql. Сервисные роли должны существовать; повторное применение к рабочим таблицам не предусмотрено. |
| [functions/oil_dds/apply_batch](functions/oil_dds/apply_batch/) | Применяет одну READY-партию в общей транзакции: проверяет контракт и конфликты, исключает повторы, заполняет реестр, hubs, links и satellites. При ошибке откатывает всю партию. |
| [functions/oil_mart/refresh_downtime](functions/oil_mart/refresh_downtime/) | После production refresh выбирает актуальные интервалы, проверяет активный скважино-день и отсутствие пересечений, рассчитывает часы и дневные суммы. |
| [functions/oil_mart/refresh_production](functions/oil_mart/refresh_production/) | Перестраивает SCD-измерения, факт скважино-дня и дневной агрегат добычи. Выбирает актуальные версии событий и проверяет однозначность измерений. |
| [functions/oil_stg/coalesce_ready_batches](functions/oil_stg/coalesce_ready_batches/) | Объединяет ограниченный диапазон READY-партий одного источника с сохранением происхождения. Работает под общей блокировкой writer. |
| [generators/oil_events](generators/oil_events/) | Программный источник событий месторождений, скважин, добычи и простоев. Baseline воспроизводим по seed; delta включает correction, replay, delete, late arrival и версию well. |
| [generators/run-oil-generator](generators/run-oil-generator/) | Запускает источник событий с настроенным TLS-подключением Kafka. Выполняется оператором явно. |
| [grants/greenplum/airflow_roles](grants/greenplum/airflow_roles/) | Назначает минимальные права вызова SECURITY DEFINER расчётных функций и доступа их владельца. |
| [grants/greenplum/cedrus_checkpoint_grant](grants/greenplum/cedrus_checkpoint_grant/) | Назначает минимальные права чтения checkpoint при согласовании границы. |
| [grants/greenplum/provision-gp-writer](grants/greenplum/provision-gp-writer/) | Создаёт ограниченного Kafka writer в GP и защищённый credential-файл. Требует явной SSH-конфигурации; не предназначен для повторного запуска вслепую. |
| [grants/greenplum/source_control_access](grants/greenplum/source_control_access/) | Назначает минимальные права контроля статуса партий и checkpoints без прямой записи. |
| [grants/kafka/enable-topic-authorizer](grants/kafka/enable-topic-authorizer/) | Включает авторизацию topic и scoped ACL. Сохраняет исходную конфигурацию и поддерживает возврат при ошибке. |
| [migration/capture_offsets](migration/capture_offsets/) | Снимает позиции партиций для согласования границы переноса. Сам по себе не устанавливает fence. |
| [migration/fence/observe-fence](migration/fence/observe-fence/) | Читает состояния известных writers и Kafka ACL/offsets. Наблюдение не заменяет живую блокировку. |
| [migration/fence/oil-migration-fence](migration/fence/oil-migration-fence/) | Root-owned controller acquire/status/release: lease, Kafka WRITE DENY для producer и pause/resume исходного GP connector. |
| [monitoring/kafka/install-ui](monitoring/kafka/install-ui/) | Устанавливает read-only панель наблюдения Kafka с выделенной identity и loopback listener. |
| [monitoring/kafka/oil_kafka_ui](monitoring/kafka/oil_kafka_ui/) | Панель наблюдения за Kafka-позициями и двумя connectors, без функций записи или запуска producer. |
| [queries/sandbox/01_stg](queries/sandbox/01_stg/) | Read-only разбор доставки и расшифровки исходного события. |
| [queries/sandbox/02_dds](queries/sandbox/02_dds/) | Read-only разбор истории и выбора актуальной версии добычи. |
| [queries/sandbox/03_marts](queries/sandbox/03_marts/) | Read-only разбор связи факта с действовавшей версией скважины. |
| [queries/sandbox/04_serving](queries/sandbox/04_serving/) | Read-only разбор управленческих показателей по месторождениям; отношение рассчитывается по суммам. |
| [queries/validation/01_checks](queries/validation/01_checks/) | Read-only SQL-проверки качества, полноты и согласованности результатов двух контуров. |
| [queries/validation/02_coalesce_checks](queries/validation/02_coalesce_checks/) | Read-only SQL-проверки объединения партий и сохранения происхождения. |
| [queries/validation/03_wave1_reconcile](queries/validation/03_wave1_reconcile/) | Read-only SQL-проверки качества, полноты и согласованности результатов двух контуров. |
| [superset/charts/performance_by_field](superset/charts/performance_by_field/) | График «Показатели по месторождениям». Использует dataset 5; параметры метрик, агрегации, временной гранулярности и отображения заданы в params. |
| [superset/charts/performance_downtime_total](superset/charts/performance_downtime_total/) | График «Часы простоев». Использует dataset 5; параметры метрик, агрегации, временной гранулярности и отображения заданы в params. |
| [superset/charts/performance_oil_total](superset/charts/performance_oil_total/) | График «Добыча, т». Использует dataset 5; параметры метрик, агрегации, временной гранулярности и отображения заданы в params. |
| [superset/charts/performance_trend](superset/charts/performance_trend/) | График «Динамика простоев по месторождениям». Использует dataset 5; параметры метрик, агрегации, временной гранулярности и отображения заданы в params. |
| [superset/charts/production_active_well_days](superset/charts/production_active_well_days/) | График «Активные скважино-дни». Использует dataset 4; параметры метрик, агрегации, временной гранулярности и отображения заданы в params. |
| [superset/charts/production_by_field](superset/charts/production_by_field/) | График «Показатели по месторождениям». Использует dataset 4; параметры метрик, агрегации, временной гранулярности и отображения заданы в params. |
| [superset/charts/production_oil_total](superset/charts/production_oil_total/) | График «Добыча, т». Использует dataset 4; параметры метрик, агрегации, временной гранулярности и отображения заданы в params. |
| [superset/charts/production_trend](superset/charts/production_trend/) | График «Динамика добычи по месторождениям». Использует dataset 4; параметры метрик, агрегации, временной гранулярности и отображения заданы в params. |
| [superset/dashboards/performance](superset/dashboards/performance/) | Панель «Эффективность добычи и простои · Greenplum». Содержит сохранённые графики, layout и фильтры региона/месторождения. Источник определяется соответствующим dataset; публикация release выполняется отдельно. |
| [superset/dashboards/production](superset/dashboards/production/) | Панель «Добыча по месторождениям · Greenplum». Содержит сохранённые графики, layout и фильтры региона/месторождения. Источник определяется соответствующим dataset; публикация release выполняется отдельно. |
| [superset/datasets/performance](superset/datasets/performance/) | Dataset 5 читает oil_mart.v_field_performance. Определяет временное поле, колонки и доступные метрики для графиков. |
| [superset/datasets/production](superset/datasets/production/) | Dataset 4 читает oil_mart.v_field_production. Определяет временное поле, колонки и доступные метрики для графиков. |
| [topics/oil.events.v1/create](topics/oil.events.v1/create/) | Создаёт topic oil.events.v1 с тремя партициями и retention 30 суток. |
| [topics/oil.events.v1/schema](topics/oil.events.v1/schema/) | Определяет envelope и четыре типа payload нефтегазового события. Контракт хранится как код; Schema Registry enforcement отдельно не настроен. |
| [views/oil_mart/v_field_performance](views/oil_mart/v_field_performance/) | Serving-представление второй цепочки: LEFT JOIN дневной добычи с дневными простоями по дате и месторождению; отсутствие простоя даёт 0 часов. |
| [views/oil_mart/v_field_production](views/oil_mart/v_field_production/) | Serving-представление первой цепочки поверх agg_field_day для отчёта добычи. |
| [views/oil_stg/v_event_parsed](views/oil_stg/v_event_parsed/) | Разбирает envelope JSON в STG: тип, ID, версию, операцию, время и payload без изменения исходного документа. |
| [workers/greenplum/install](workers/greenplum/install/) | Устанавливает GP Connect worker и его служебные topics. |
| [workers/iceberg/install](workers/iceberg/install/) | Устанавливает отдельный Iceberg Connect worker и control/config/offset/status topics. |

Смежный репозиторий: [Lakehouse](https://github.com/ncuho/dlh-scripts).

## Online-перенос производственной цепочки

Историческая загрузка читает исходные таблицы GP напрямую под SHARE-lock. Генератор и Iceberg consumer работают; GP consumer и исходные расчёты приостановлены на окно загрузки и сверок. После COMMIT и Resume backlog обрабатывается штатно. REFRESH использует полный диапазон C0–C1 с перекрытием; отдельные source copies не создаются.

Полный исходный/целевой SQL прокомментирован. В целевом репозитории `pipelines/production_online` содержит 20 отдельных папок: DDL, INITIAL, REFRESH, проверки и назначение каждого объекта. Это принятый бизнес-контракт первой цепочки. Остальные SQL относятся к альтернативным проекциям и следующей волне; не запускайте их поверх этого release. В Git не записываются runtime receipts, snapshots и секреты.

LakeKeeper управляет таблицами и доступом через CIAM identities, Spark выполняет бизнес-проекции, Cedrus переносит историю и обслуживает SQL, Airflow запускает принятую обработку. Kafka Connect сохраняет JSON и координаты, обязательный received_at фиксируется SMT. Kafbat UI наблюдает topics/messages/groups/Connect через приватный SSH-туннель.
