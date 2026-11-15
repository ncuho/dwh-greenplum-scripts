# Модель и расчёты

## Добыча и простой

| Объект | Гранулярность и назначение |
|---|---|
| `ods.og_tbl_production_volume` | Месячный факт исходной добычи по скважине; распределение по `id`. |
| `ods.og_tbl_well` | Скважина и её атрибуты. |
| `ref.calendar` | Календарная дата; справочник реплицирован на сегментах. |
| `dds.dim_well_scd2` | Версия скважины с интервалом `[valid_from, valid_to)`. |
| `dds.fact_downtime_interval` | Интервал простоя скважины. |
| `dds.fact_production_day` | Скважина и день; хранение append-optimized column, сжатие zlib, распределение по `well_id`, секционирование по диапазону `business_date`, включая default-секцию. |
| `dds.v_production_with_well` | Суточная добыча с названием скважины. |

[`etl.rebuild_production_day`](../functions/etl/rebuild_production_day.sql) проверяет временной диапазон, пересечение версий и простоев, корректность часов работы. Затем создаёт временные таблицы весов и округлённых долей, удаляет прежние строки выбранного периода и записывает пересчитанные значения. Разрешены полные месяцы в 2025 году и пакет `1`; это ограничение самой функции.

[Операции начального формирования](../dml/bootstrap) содержат ту же последовательность временных весов, округлённых долей и вставки. Объекты `production_weights` и `production_floors` — временные, с областью действия транзакции. [Проверка истории](../tests/sql/quality) содержит отдельные запросы на пересечения версий и соответствие каждой строки добычи версии скважины.

## Месячные результаты и энергия

`dds.fact_production_plan_month` хранит план по скважине, месяцу и сценарию. `dds.fact_energy_day` — затраты и потребление по скважине и дню. `ref.energy_tariff`, домен `ref.tariff_rate` и функция `etl.f_energy_cost` задают тариф и расчёт стоимости. `dm.field_month_performance` хранит результат по месторождению и месяцу. [`etl.rebuild_marts`](../functions/etl/rebuild_marts.sql) проверяет состав пакета и исходные данные, строит семь витрин и записывает результат выполнения в `ctl.task_run`. [`etl.run_daily_batch`](../functions/etl/run_daily_batch.sql) сначала вызывает `etl.rebuild_production_day`, затем `etl.rebuild_marts`. [`dm.v_production_dashboard`](../ddl/views/dm/v_production_dashboard.sql) соединяет витрину с `ods.og_tbl_locality`. [`dm.mv_field_month_energy`](../ddl/materialized_views/dm/mv_field_month_energy.sql) — материализованный агрегат; его обновление представлено [отдельной операцией](../dml/maintenance/refresh_field_month_energy.sql).

## Ремонты

`dds.dim_equipment` описывает оборудование, `dds.fact_repair_order` — заказы, `dds.fact_repair_operation` — работы и их стоимость. В `dm.repair_cost_month` расположен месячный итог по скважине. На справочнике оборудования определены B-tree индекс по коду и bitmap-индекс по типу; статус заказа использует `ref.work_state`.

## Граница выборки

Репозиторий содержит исходные определения перечисленных объектов, но не все таблицы и все функции Greenplum. Для `etl.rebuild_marts` вне этой выборки остаются таблицы `ods.og_tbl_servicecall`, `dds.fact_lab_sample`, `dds.fact_quality_measurement`, `dds.fact_shipment`, `dds.fact_shipment_item`, а также витрины `dm.energy_intensity_day`, `dm.quality_compliance_day`, `dm.service_production_impact`, `dm.shipment_balance_month`, `dm.well_day_balance`. Файлами этой выборки создать весь расчёт нельзя. Расписания, внешние источники, политика доступа и отчёты потребителей требуют отдельного обследования. Исходные функции содержат транзакционные изменения; запросы из `dql` читают данные.

Статус входного пакета хранится в `ctl.load_batch`; исходная [операция завершения пакета](../dml/bootstrap/ctl/load_batch__finalize.sql) обновляет состояние и время завершения. `ctl.task_run` хранит сведения о выполнении, `ctl.run_id_seq` выдаёт идентификатор запуска.
