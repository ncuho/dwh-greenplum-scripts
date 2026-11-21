# Вебинар: 22 шага — от Greenplum к Lakehouse

Состояние до показа: первая волна добычи уже перенесена и сверена на зафиксированной границе; dashboard 5 остаётся её неподвижным baseline. Вторая бизнес-волна простоев ещё не перенесена: пустой dashboard 6 подготовлен к отдельной управляемой публикации. Все данные синтетические; сценарий не является полностью click-only: два действия выполняет оператор Kafka через CLI/API.

**1. Открываем два контура.** Показываем Greenplum в VK Cloud и сервисы VK Data Platform. Объясняем, что исходные расчёты пока живут в GP, а Iceberg/LakeKeeper и CedrusData Engine принимают перенесённые цепочки по согласованной границе.

**2. Проверяем состояние и версии.** Открываем сервисы GP, Kafka/Connect, Airflow, LakeKeeper, Cedrus, Data Catalog и Superset; показываем текущие статусы и реальные версии. CIAM runtime подтверждён как 26.1.0; Kafka одноузловая, RF=1, поэтому это не демонстрация HA.

**3. Разбираем путь событий.** Генератор выдаёт синтетические field/well/production_day/downtime в `oil.events.v1`, source Kafka Connect доставляет события в GP STG. Read-only Kafka-панель показывает состояние и offsets, но не запускает producer и не переключает коннекторы.

**4. Показываем три слоя GP.** В Greenplum и Data Catalog открываем `oil_stg`, `oil_dds`, `oil_mart`: приём и checkpoints, Raw Vault с историей, затем измерения и факты в стиле Kimball. Объясняем, что учебная реализация использует DV-паттерны и не заявляется сертифицированной DV 2.0.

**5. Открываем отчёты источника.** В Superset dashboard 3 «Добыча нефти по месторождениям» показывает тонны и активные скважино-дни, dashboard 4 — ещё и часы простоев. Статус ACTIVE на полный день — прокси фонда при полноте событий, а не измерение фактически отработанных часов.

**6. Показываем первую волну DLH.** Открываем dashboard 5 «Добыча нефти · Lakehouse» с таблицей `dlh.oil_mart.agg_field_day`; это baseline на согласованной границе, не автоматическая копия всех последующих изменений. Исходный dashboard 3 продолжает работать.

**7. Исследуем lineage.** В Data Catalog открываем `webinar_superset.dashboard_4` и идём через графики, `og_greenplum.og_dwh.oil_mart.v_field_performance`, факты, измерения и DDS к исходному топику. Переходим к column lineage и поясняем, что связи зарегистрированы вручную по фактическому SQL, а не получены полностью автоматической интеграцией.

**8. Исключаем ненужную сущность.** Открываем `og_greenplum.og_dwh.oil_mart.legacy_field_month_export_2024`: 60 строк получены из 2025 года с коэффициентом 0.95 и сдвигом на 2024-й, это не реальные исторические измерения. Демоархив исключён из обеих волн, scheduled DAG и BI-потребитель не настроены; для реального объекта нужны полноценный аудит использования и бизнес-согласование.

**9. Смотрим код и контракты.** В GitHub открываем SQL исходного GP и код подготовленной второй волны; в каталоге — `webinar_kafka."oil.events.v1"`, JSON Schema и глоссарий `OilWebinar`. Schema в каталоге документирует контракт, но сама по себе не доказывает применение Schema Registry.

**10. Показываем пустую целевую панель и роли.** В Superset открываем dashboard 6 «Эффективность добычи и простои · Lakehouse»: dataset 8 сейчас читает пустую `dlh.oil_demo_template.field_performance`. В LakeKeeper показываем роли `oil_dlh_reader` и `oil_dlh_engineer`; права на каталог, S3, движок и Superset — разные уровни доступа.

**11. Выбираем законченную вторую цепочку.** Переносим отчёт простоев вместе с историей downtime и необходимыми общими field/well/production_day; общие зависимости не копируются вслепую. В каталоге показываем отдельный `webinar_wave2_connect.webinar-oil-wave2-iceberg` и пустой `dlh_trino.dlh.oil_stg.event_log_wave2`: PAUSED и конфигурационные связи ещё не являются выполненной загрузкой.

**12. Проверяем готовность к границе.** Сверяем topic ID, partitions, retention, текущие producer и GP/target connectors; прежние offsets `[5170,5196,5159]` — исторический ориентир первой волны, а не универсальная новая граница. В Airflow DAG `oil_gp_release` запускаем с `{}` и убеждаемся, что source batches применены; один вызов обрабатывает не более 100 READY партий.

**13. Создаём INITIAL.** В Airflow → `oil_wave2_release` → Trigger DAG with config запускаем `{"action":"build","mode":"initial","schema":"oil_r_demo_initial_20261122"}` с новым уникальным именем. DAG удерживает fence, сверяет offsets/checkpoints и состояние STG→DDS, затем создаёт полный GP baseline и 21 отдельную таблицу release.

**14. Проверяем release и каталог.** В логах Airflow ожидаем `BUILD_RECONCILED` и `CATALOG_READY`, нулевые DQ и сохранённые manifest/snapshots; на стенде изолированная проверка показала порядок нескольких минут, а не мгновенную транзакцию. В Data Catalog открываем реальные `oil_i_...baseline_event` и `oil_r_...` объекты и lineage от GP event; отдельные Iceberg commits не образуют одной межтабличной транзакции.

**15. Даём доступ reader на выпуск.** В UI LakeKeeper находим конкретный новый release namespace и назначаем роли `oil_dlh_reader` право `select` на обе таблицы `field_performance` и `agg_field_day`. PUBLISH сам повторно проверяет текущие grants и snapshot IDs через verifier; наличие ролей в каталоге не заменяет отдельную проверку доступа пользователя в Superset.

**16. Показываем INITIAL в подготовленной панели.** Если текущий dataset 8 всё ещё указывает на template, в Airflow запускаем `{"action":"publish","schema":"oil_r_demo_initial_20261122","dataset_id":8,"database_id":2,"expected_schema":"oil_demo_template","expected_table":"field_performance","table":"field_performance"}`. После `PUBLISH_VERIFIED` и `CATALOG_PUBLISHED` обновляем dashboard 6 и сравниваем исходный GP dashboard 4 с целевым INITIAL на том же cut.

**17. Включаем target consumer.** Оператор выполняет согласованное действие Kafka Connect `PUT .../connectors/webinar-oil-wave2-iceberg/resume` для отдельного worker на localhost:18085; точная команда и SSH приведены ниже. Read-only Kafka UI показывает изменение состояния и lag, но не выполняет само управление.

**18. Генерируем управляемые изменения.** Оператор один раз запускает установленный producer с параметрами ниже: пять сообщений, включая одно дословное повторение. Добыча выбранного well/day увеличивается на 1.250 т; одно событие простоя удаляется, другое приходит с опозданием, а версия well уточняется — общие число/часы простоев при этом могут не измениться.

**19. Обрабатываем источник и доставку.** В Airflow запускаем `oil_gp_release` с `{}`, ждём успеха и проверяем source checkpoint и отсутствие READY/FAILED; отдельно ждём поступления всех новых offsets в raw Iceberg через wave2 connector. Для подтверждения исправления, replay, удаления и late arrival нужны event history и послойный `EXCEPT ALL`, а не только количество записей или общая сумма.

**20. Собираем REFRESH.** В Airflow запускаем `{"action":"build","mode":"refresh","schema":"oil_r_demo_refresh_20261122","initial_schema":"oil_r_demo_initial_20261122"}`. DAG повторно использует INITIAL baseline, фиксирует новый raw snapshot и диапазоны `[start,end)`, строит новый namespace и останавливается при пропущенном offset или ошибке сверки; ожидаем `BUILD_RECONCILED` и `CATALOG_READY`.

**21. Проверяем и переключаем вторую панель.** В LakeKeeper выдаём reader select на две serving-таблицы нового refresh release; сравниваем GP/DLH на новой общей границе, включая историю, строки, тонны, часы и дневную детализацию. В Airflow PUBLISH используем `{"action":"publish","schema":"oil_r_demo_refresh_20261122","dataset_id":8,"database_id":2,"expected_schema":"oil_r_demo_initial_20261122","expected_table":"field_performance","table":"field_performance"}` только если dataset действительно указывает на INITIAL; затем проверяем dashboard 6 и новые lineage.

**22. Фиксируем результат и следующую волну.** Dashboard 5 по умолчанию остаётся frozen baseline первой волны: после изменения общей добычи нельзя сравнивать его с обновлённым GP как с актуальной синхронной копией. Если нужны оба отчёта на новом cut, администратор отдельно в Superset Edit Dataset 6 меняет schema на новый `oil_r_...`, table на `agg_field_day` после проверки grants/сверки; у publisher нет прав на dataset 6. Показать дневную детализацию через SQL/filter по дате либо Explore с P1D: не обещать изменение месячных сумм простоев.

Перед запуском заменить имена release на действительно свободные, проверить актуальные права, состояние topic/connector, UI-доступ и результат последней репетиции. При ошибке не повторять CTAS вслепую: проверить evidence, состояние fence и зависшие запросы; `catalog_ready`/`catalog_published` повторяются отдельно. Ранее тестовые release namespaces и metadata удалялись после проверок; evidence не является действующим INITIAL baseline для REFRESH.

## Два операторских действия на Kafka VM

Команды подготовлены для ручного выполнения только во время демо, после подтверждения безопасного cut и retention. Сначала открыть SSH к Kafka VM:

```bash
ssh -F /Users/n.surovegin/Desktop/AI/vk-data-migration-2026-11-15/runbooks/gp-ssh.conf \
  -o ProxyJump=gp-demo-coordinator -i ~/.ssh/vk_migration_demo_20261115_rsa ubuntu@10.77.25.20
```

В этой сессии включить именно target connector и проверить его состояние:

```bash
curl -fsS -X PUT http://127.0.0.1:18085/connectors/webinar-oil-wave2-iceberg/resume
curl -fsS http://127.0.0.1:18085/connectors/webinar-oil-wave2-iceberg/status
```

После подтверждения RUNNING однократно отправить пять delta-событий:

```bash
sudo -u kafka /opt/kafka-demo/oil-generator/run-oil-generator.sh \
  --phase delta --seed 42 --fields 5 --wells 40 --days 365 --kafka
```

Для постановки target connector на паузу после сценария использовать `curl -fsS -X PUT http://127.0.0.1:18085/connectors/webinar-oil-wave2-iceberg/pause`, затем повторить GET `/status` и убедиться в PAUSED. Wrapper сам использует настроенные TLS-файлы; секреты в команду не добавлять. До эфира проверен офлайн-вывод генератора (ровно пять строк), а не повторная публикация этих событий в Kafka.

## Подтверждённая репетиция и её границы

На изолированном наборе Airflow INITIAL завершился `SUCCESS`, создан release и зарегистрирован `CATALOG_READY`. Затем Airflow PUBLISH прошёл до `PUBLISH_VERIFIED` и `CATALOG_PUBLISHED`, четыре принудительных chart job завершились `done` без ошибок. После обратимой проверки dataset 8 возвращён точно на пустой `oil_demo_template.field_performance`; четыре связи template→chart и все описания в каталоге проверены на совпадение с исходным состоянием (`reporting/original-preprobe-catalog.json`, `reporting/preprobe-catalog.json`, `reporting/pubprobe-chart-evidence.json`). Эта репетиция не является бизнес-миграцией; визуальная проверка панели и нажатия фильтров в браузере пользователя ещё нужны.

Финальный изолированный REFRESH также завершился Airflow `SUCCESS` и `CATALOG_READY` с нулевыми проверками; окно новых Kafka-событий было пустым. Это подтверждает повторное использование baseline и ветку построения release, но не доказывает end-to-end обработку новых сообщений Kafka в боевом потоке. После репетиции по точным ID удалены 53 связанные metadata edges, 43 пробные таблицы каталога и три schema помечены удалёнными; физические тестовые namespaces и данные в их зарегистрированных S3 locations очищены, отсутствие подтверждено отдельно. Evidence: `catalog/final-probe-ids.json`, `catalog/final-probe-edge-cleanup.json`, `catalog/final-probe-cleanup.json`, `target/final-purge-evidence.jsonl` и соответствующие финальные проверки S3. Постоянные исходные объекты, пустая панель и её template сохранены.

Итоговый readback после cleanup: dataset 8 снова указывает на `oil_demo_template.field_performance`, четыре upstream связи и описания панелей совпадают с состоянием до репетиции; см. `reporting/final-restoration-evidence.json`. Пользовательский браузер и взаимодействие с фильтрами всё ещё необходимо проверить перед эфиром.
