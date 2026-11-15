\set ON_ERROR_STOP on

-- Greenplum 6.26.2. New og_dwh database only; existing DLH is read-only.


BEGIN;

\ir ../../ddl/schemas/ods.sql

\ir ../../ddl/schemas/mart.sql

\ir ../../ddl/schemas/ref.sql

\ir ../../ddl/schemas/stg.sql

\ir ../../ddl/schemas/dds.sql

\ir ../../ddl/schemas/dm.sql

\ir ../../ddl/schemas/ctl.sql

\ir ../../ddl/schemas/etl.sql

\ir ../../ddl/domains/ref/tariff_rate.sql

\ir ../../ddl/types/ref/work_state.sql

\ir ../../ddl/sequences/ctl/run_id_seq.sql

\ir ../../ddl/tables/mart/bo_werks_text.sql

\ir ../../ddl/tables/mart/dm_hse_incidents.sql

\ir ../../ddl/tables/mart/dm_hse_one.sql

\ir ../../ddl/tables/mart/dm_incidents.sql

\ir ../../ddl/tables/mart/dm_project_status.sql

\ir ../../ddl/tables/mart/dm_well.sql

\ir ../../ddl/tables/mart/dm_well_more.sql

\ir ../../ddl/tables/mart/dm_well_production.sql

\ir ../../ddl/tables/mart/og_bs_area.sql

\ir ../../ddl/tables/mart/og_report.sql

\ir ../../ddl/tables/ods/og_asu_work_assignment.sql

\ir ../../ddl/tables/ods/og_but000.sql

\ir ../../ddl/tables/ods/og_crmd_activity_h.sql

\ir ../../ddl/tables/ods/og_crmd_orderadm_h.sql

\ir ../../ddl/tables/ods/og_crmd_orderadm_i.sql

\ir ../../ddl/tables/ods/og_crmd_partner.sql

\ir ../../ddl/tables/ods/og_pa0001.sql

\ir ../../ddl/tables/ods/og_pa0002.sql

\ir ../../ddl/tables/ods/og_project.sql

\ir ../../ddl/tables/ods/og_t500p.sql

\ir ../../ddl/tables/ods/og_task.sql

\ir ../../ddl/tables/ods/og_tbl_changerequest.sql

\ir ../../ddl/tables/ods/og_tbl_cmdb.sql

\ir ../../ddl/tables/ods/og_tbl_comment.sql

\ir ../../ddl/tables/ods/og_tbl_company.sql

\ir ../../ddl/tables/ods/og_tbl_directory.sql

\ir ../../ddl/tables/ods/og_tbl_employee.sql

\ir ../../ddl/tables/ods/og_tbl_equipment_repair.sql

\ir ../../ddl/tables/ods/og_tbl_kb.sql

\ir ../../ddl/tables/ods/og_tbl_locality.sql

\ir ../../ddl/tables/ods/og_tbl_mark.sql

\ir ../../ddl/tables/ods/og_tbl_ou.sql

\ir ../../ddl/tables/ods/og_tbl_priority.sql

\ir ../../ddl/tables/ods/og_tbl_production_volume.sql

\ir ../../ddl/tables/ods/og_tbl_servicecall.sql

\ir ../../ddl/tables/ods/og_tbl_servicecateg.sql

\ir ../../ddl/tables/ods/og_tbl_slmservice.sql

\ir ../../ddl/tables/ods/og_tbl_team.sql

\ir ../../ddl/tables/ods/og_tbl_typeworks.sql

\ir ../../ddl/tables/ods/og_tbl_well.sql

\ir ../../ddl/tables/ods/og_tbl_well_incident.sql

\ir ../../ddl/tables/ods/og_tbl_workrecord.sql

\ir ../../ddl/tables/ods/og_ws_user.sql

\ir ../../ddl/tables/ods/og_zcbap_infsys.sql

\ir ../../ddl/tables/ods/og_zgr_it.sql

\ir ../../ddl/tables/ods/og_znapr.sql

\ir ../../ddl/tables/ref/unit.sql

\ir ../../ddl/tables/ref/calendar.sql

\ir ../../ddl/tables/ref/product.sql

\ir ../../ddl/tables/ref/repair_type.sql

\ir ../../ddl/tables/ref/downtime_reason.sql

\ir ../../ddl/tables/ref/sensor_type.sql

\ir ../../ddl/tables/ref/energy_tariff.sql

\ir ../../ddl/tables/ref/quality_spec.sql

\ir ../../ddl/tables/stg/measurement_event.sql

\ir ../../ddl/tables/stg/repair_event.sql

\ir ../../ddl/tables/stg/lab_event.sql

\ir ../../ddl/tables/stg/shipment_event.sql

\ir ../../ddl/tables/dds/dim_well_scd2.sql

\ir ../../ddl/tables/dds/dim_equipment.sql

\ir ../../ddl/tables/dds/dim_contract.sql

\ir ../../ddl/tables/dds/bridge_equipment_well_history.sql

\ir ../../ddl/tables/dds/fact_production_day.sql

\ir ../../ddl/tables/dds/fact_telemetry_hour.sql

\ir ../../ddl/tables/dds/fact_downtime_interval.sql

\ir ../../ddl/tables/dds/fact_repair_order.sql

\ir ../../ddl/tables/dds/fact_repair_operation.sql

\ir ../../ddl/tables/dds/fact_energy_day.sql

\ir ../../ddl/tables/dds/fact_lab_sample.sql

\ir ../../ddl/tables/dds/fact_quality_measurement.sql

\ir ../../ddl/tables/dds/fact_production_plan_month.sql

\ir ../../ddl/tables/dds/fact_shipment.sql

\ir ../../ddl/tables/dds/fact_shipment_item.sql

\ir ../../ddl/tables/dm/well_day_balance.sql

\ir ../../ddl/tables/dm/field_month_performance.sql

\ir ../../ddl/tables/dm/repair_cost_month.sql

\ir ../../ddl/tables/dm/energy_intensity_day.sql

\ir ../../ddl/tables/dm/quality_compliance_day.sql

\ir ../../ddl/tables/dm/shipment_balance_month.sql

\ir ../../ddl/tables/dm/service_production_impact.sql

\ir ../../ddl/tables/ctl/load_batch.sql

\ir ../../ddl/tables/ctl/task_run.sql

\ir ../../ddl/tables/ctl/quality_result.sql

\ir ../../ddl/tables/ctl/source_asset.sql

\ir ../../ddl/tables/ctl/publication_release.sql

\ir ../../ddl/indexes/dds/ix_equipment_code.sql

\ir ../../ddl/indexes/dds/ix_equipment_type_bitmap.sql

COMMIT;
