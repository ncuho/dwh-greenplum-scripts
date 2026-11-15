# Объекты модели

85 логических таблиц; дочерние физические partition relations не считаются отдельными бизнес-таблицами. Domain DDS и имена витрин сохранены.

| Объект | Строк в проверенном экземпляре | DDL |
|---|---:|---|
| `mart.bo_werks_text` | 8 | [SQL](../ddl/tables/mart/bo_werks_text.sql) |
| `mart.dm_hse_incidents` | 392 | [SQL](../ddl/tables/mart/dm_hse_incidents.sql) |
| `mart.dm_hse_one` | 400 | [SQL](../ddl/tables/mart/dm_hse_one.sql) |
| `mart.dm_incidents` | 100 | [SQL](../ddl/tables/mart/dm_incidents.sql) |
| `mart.dm_project_status` | 39 | [SQL](../ddl/tables/mart/dm_project_status.sql) |
| `mart.dm_well` | 200 | [SQL](../ddl/tables/mart/dm_well.sql) |
| `mart.dm_well_more` | 200 | [SQL](../ddl/tables/mart/dm_well_more.sql) |
| `mart.dm_well_production` | 2400 | [SQL](../ddl/tables/mart/dm_well_production.sql) |
| `mart.og_bs_area` | 6 | [SQL](../ddl/tables/mart/og_bs_area.sql) |
| `mart.og_report` | 480 | [SQL](../ddl/tables/mart/og_report.sql) |
| `ods.og_asu_work_assignment` | 2000 | [SQL](../ddl/tables/ods/og_asu_work_assignment.sql) |
| `ods.og_but000` | 60 | [SQL](../ddl/tables/ods/og_but000.sql) |
| `ods.og_crmd_activity_h` | 500 | [SQL](../ddl/tables/ods/og_crmd_activity_h.sql) |
| `ods.og_crmd_orderadm_h` | 300 | [SQL](../ddl/tables/ods/og_crmd_orderadm_h.sql) |
| `ods.og_crmd_orderadm_i` | 800 | [SQL](../ddl/tables/ods/og_crmd_orderadm_i.sql) |
| `ods.og_crmd_partner` | 400 | [SQL](../ddl/tables/ods/og_crmd_partner.sql) |
| `ods.og_pa0001` | 150 | [SQL](../ddl/tables/ods/og_pa0001.sql) |
| `ods.og_pa0002` | 150 | [SQL](../ddl/tables/ods/og_pa0002.sql) |
| `ods.og_project` | 40 | [SQL](../ddl/tables/ods/og_project.sql) |
| `ods.og_t500 p` | 10 | [SQL](../ddl/tables/ods/og_t500 p.sql) |
| `ods.og_task` | 800 | [SQL](../ddl/tables/ods/og_task.sql) |
| `ods.og_tbl_changerequest` | 200 | [SQL](../ddl/tables/ods/og_tbl_changerequest.sql) |
| `ods.og_tbl_cmdb` | 200 | [SQL](../ddl/tables/ods/og_tbl_cmdb.sql) |
| `ods.og_tbl_comment` | 8122 | [SQL](../ddl/tables/ods/og_tbl_comment.sql) |
| `ods.og_tbl_company` | 15 | [SQL](../ddl/tables/ods/og_tbl_company.sql) |
| `ods.og_tbl_directory` | 30 | [SQL](../ddl/tables/ods/og_tbl_directory.sql) |
| `ods.og_tbl_employee` | 150 | [SQL](../ddl/tables/ods/og_tbl_employee.sql) |
| `ods.og_tbl_equipment_repair` | 500 | [SQL](../ddl/tables/ods/og_tbl_equipment_repair.sql) |
| `ods.og_tbl_kb` | 60 | [SQL](../ddl/tables/ods/og_tbl_kb.sql) |
| `ods.og_tbl_locality` | 20 | [SQL](../ddl/tables/ods/og_tbl_locality.sql) |
| `ods.og_tbl_mark` | 10 | [SQL](../ddl/tables/ods/og_tbl_mark.sql) |
| `ods.og_tbl_ou` | 20 | [SQL](../ddl/tables/ods/og_tbl_ou.sql) |
| `ods.og_tbl_priority` | 4 | [SQL](../ddl/tables/ods/og_tbl_priority.sql) |
| `ods.og_tbl_production_volume` | 2400 | [SQL](../ddl/tables/ods/og_tbl_production_volume.sql) |
| `ods.og_tbl_servicecall` | 4000 | [SQL](../ddl/tables/ods/og_tbl_servicecall.sql) |
| `ods.og_tbl_servicecateg` | 15 | [SQL](../ddl/tables/ods/og_tbl_servicecateg.sql) |
| `ods.og_tbl_slmservice` | 60 | [SQL](../ddl/tables/ods/og_tbl_slmservice.sql) |
| `ods.og_tbl_team` | 12 | [SQL](../ddl/tables/ods/og_tbl_team.sql) |
| `ods.og_tbl_typeworks` | 8 | [SQL](../ddl/tables/ods/og_tbl_typeworks.sql) |
| `ods.og_tbl_well` | 200 | [SQL](../ddl/tables/ods/og_tbl_well.sql) |
| `ods.og_tbl_well_incident` | 800 | [SQL](../ddl/tables/ods/og_tbl_well_incident.sql) |
| `ods.og_tbl_workrecord` | 11970 | [SQL](../ddl/tables/ods/og_tbl_workrecord.sql) |
| `ods.og_ws_user` | 150 | [SQL](../ddl/tables/ods/og_ws_user.sql) |
| `ods.og_zcbap_infsys` | 18 | [SQL](../ddl/tables/ods/og_zcbap_infsys.sql) |
| `ods.og_zgr_it` | 10 | [SQL](../ddl/tables/ods/og_zgr_it.sql) |
| `ods.og_znapr` | 8 | [SQL](../ddl/tables/ods/og_znapr.sql) |
| `ref.unit` | 12 | [SQL](../ddl/tables/ref/unit.sql) |
| `ref.calendar` | 365 | [SQL](../ddl/tables/ref/calendar.sql) |
| `ref.product` | 3 | [SQL](../ddl/tables/ref/product.sql) |
| `ref.repair_type` | 6 | [SQL](../ddl/tables/ref/repair_type.sql) |
| `ref.downtime_reason` | 6 | [SQL](../ddl/tables/ref/downtime_reason.sql) |
| `ref.sensor_type` | 4 | [SQL](../ddl/tables/ref/sensor_type.sql) |
| `ref.energy_tariff` | 4 | [SQL](../ddl/tables/ref/energy_tariff.sql) |
| `ref.quality_spec` | 6 | [SQL](../ddl/tables/ref/quality_spec.sql) |
| `stg.measurement_event` | 1752000 | [SQL](../ddl/tables/stg/measurement_event.sql) |
| `stg.repair_event` | 2400 | [SQL](../ddl/tables/stg/repair_event.sql) |
| `stg.lab_event` | 7200 | [SQL](../ddl/tables/stg/lab_event.sql) |
| `stg.shipment_event` | 240 | [SQL](../ddl/tables/stg/shipment_event.sql) |
| `dds.dim_well_scd2` | 400 | [SQL](../ddl/tables/dds/dim_well_scd2.sql) |
| `dds.dim_equipment` | 400 | [SQL](../ddl/tables/dds/dim_equipment.sql) |
| `dds.dim_contract` | 20 | [SQL](../ddl/tables/dds/dim_contract.sql) |
| `dds.bridge_equipment_well_history` | 400 | [SQL](../ddl/tables/dds/bridge_equipment_well_history.sql) |
| `dds.fact_production_day` | 73000 | [SQL](../ddl/tables/dds/fact_production_day.sql) |
| `dds.fact_telemetry_hour` | 1752000 | [SQL](../ddl/tables/dds/fact_telemetry_hour.sql) |
| `dds.fact_downtime_interval` | 800 | [SQL](../ddl/tables/dds/fact_downtime_interval.sql) |
| `dds.fact_repair_order` | 800 | [SQL](../ddl/tables/dds/fact_repair_order.sql) |
| `dds.fact_repair_operation` | 2400 | [SQL](../ddl/tables/dds/fact_repair_operation.sql) |
| `dds.fact_energy_day` | 73000 | [SQL](../ddl/tables/dds/fact_energy_day.sql) |
| `dds.fact_lab_sample` | 2400 | [SQL](../ddl/tables/dds/fact_lab_sample.sql) |
| `dds.fact_quality_measurement` | 7200 | [SQL](../ddl/tables/dds/fact_quality_measurement.sql) |
| `dds.fact_production_plan_month` | 4800 | [SQL](../ddl/tables/dds/fact_production_plan_month.sql) |
| `dds.fact_shipment` | 240 | [SQL](../ddl/tables/dds/fact_shipment.sql) |
| `dds.fact_shipment_item` | 240 | [SQL](../ddl/tables/dds/fact_shipment_item.sql) |
| `dm.well_day_balance` | 73000 | [SQL](../ddl/tables/dm/well_day_balance.sql) |
| `dm.field_month_performance` | 240 | [SQL](../ddl/tables/dm/field_month_performance.sql) |
| `dm.repair_cost_month` | 2400 | [SQL](../ddl/tables/dm/repair_cost_month.sql) |
| `dm.energy_intensity_day` | 73000 | [SQL](../ddl/tables/dm/energy_intensity_day.sql) |
| `dm.quality_compliance_day` | 720 | [SQL](../ddl/tables/dm/quality_compliance_day.sql) |
| `dm.shipment_balance_month` | 240 | [SQL](../ddl/tables/dm/shipment_balance_month.sql) |
| `dm.service_production_impact` | 200 | [SQL](../ddl/tables/dm/service_production_impact.sql) |
| `ctl.load_batch` | 1 | [SQL](../ddl/tables/ctl/load_batch.sql) |
| `ctl.task_run` | 2 | [SQL](../ddl/tables/ctl/task_run.sql) |
| `ctl.quality_result` | 143 | [SQL](../ddl/tables/ctl/quality_result.sql) |
| `ctl.source_asset` | 46 | [SQL](../ddl/tables/ctl/source_asset.sql) |
| `ctl.publication_release` | 1 | [SQL](../ddl/tables/ctl/publication_release.sql) |

Полный состав колонок и типов — `metadata/actual-gp-columns.json`; гранулярности и связи — `metadata/asset-manifest.json`; фактические вычислительные зависимости — `metadata/dependencies.json`. Связи модели не означают автоматически enforced FK.
