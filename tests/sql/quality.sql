\set ON_ERROR_STOP on

SET statement_timeout='120s';

\ir quality/key_mart.bo_werks_text.sql

\ir quality/key_mart.dm_hse_incidents.sql

\ir quality/key_mart.dm_hse_one.sql

\ir quality/key_mart.dm_incidents.sql

\ir quality/key_mart.dm_project_status.sql

\ir quality/key_mart.dm_well.sql

\ir quality/key_mart.dm_well_more.sql

\ir quality/key_mart.dm_well_production.sql

\ir quality/key_mart.og_bs_area.sql

\ir quality/key_mart.og_report.sql

\ir quality/key_ods.og_asu_work_assignment.sql

\ir quality/key_ods.og_but000.sql

\ir quality/key_ods.og_crmd_activity_h.sql

\ir quality/key_ods.og_crmd_orderadm_h.sql

\ir quality/key_ods.og_crmd_orderadm_i.sql

\ir quality/key_ods.og_crmd_partner.sql

\ir quality/key_ods.og_pa0001.sql

\ir quality/key_ods.og_pa0002.sql

\ir quality/key_ods.og_project.sql

\ir quality/key_ods.og_t500p.sql

\ir quality/key_ods.og_task.sql

\ir quality/key_ods.og_tbl_changerequest.sql

\ir quality/key_ods.og_tbl_cmdb.sql

\ir quality/key_ods.og_tbl_comment.sql

\ir quality/key_ods.og_tbl_company.sql

\ir quality/key_ods.og_tbl_directory.sql

\ir quality/key_ods.og_tbl_employee.sql

\ir quality/key_ods.og_tbl_equipment_repair.sql

\ir quality/key_ods.og_tbl_kb.sql

\ir quality/key_ods.og_tbl_locality.sql

\ir quality/key_ods.og_tbl_mark.sql

\ir quality/key_ods.og_tbl_ou.sql

\ir quality/key_ods.og_tbl_priority.sql

\ir quality/key_ods.og_tbl_production_volume.sql

\ir quality/key_ods.og_tbl_servicecall.sql

\ir quality/key_ods.og_tbl_servicecateg.sql

\ir quality/key_ods.og_tbl_slmservice.sql

\ir quality/key_ods.og_tbl_team.sql

\ir quality/key_ods.og_tbl_typeworks.sql

\ir quality/key_ods.og_tbl_well.sql

\ir quality/key_ods.og_tbl_well_incident.sql

\ir quality/key_ods.og_tbl_workrecord.sql

\ir quality/key_ods.og_ws_user.sql

\ir quality/key_ods.og_zcbap_infsys.sql

\ir quality/key_ods.og_zgr_it.sql

\ir quality/key_ods.og_znapr.sql

\ir quality/key_ref.unit.sql

\ir quality/key_ref.calendar.sql

\ir quality/key_ref.product.sql

\ir quality/key_ref.repair_type.sql

\ir quality/key_ref.downtime_reason.sql

\ir quality/key_ref.sensor_type.sql

\ir quality/key_ref.energy_tariff.sql

\ir quality/key_ref.quality_spec.sql

\ir quality/key_stg.measurement_event.sql

\ir quality/key_stg.repair_event.sql

\ir quality/key_stg.lab_event.sql

\ir quality/key_stg.shipment_event.sql

\ir quality/key_dds.dim_well_scd2.sql

\ir quality/key_dds.dim_equipment.sql

\ir quality/key_dds.dim_contract.sql

\ir quality/key_dds.bridge_equipment_well_history.sql

\ir quality/key_dds.fact_production_day.sql

\ir quality/key_dds.fact_telemetry_hour.sql

\ir quality/key_dds.fact_downtime_interval.sql

\ir quality/key_dds.fact_repair_order.sql

\ir quality/key_dds.fact_repair_operation.sql

\ir quality/key_dds.fact_energy_day.sql

\ir quality/key_dds.fact_lab_sample.sql

\ir quality/key_dds.fact_quality_measurement.sql

\ir quality/key_dds.fact_production_plan_month.sql

\ir quality/key_dds.fact_shipment.sql

\ir quality/key_dds.fact_shipment_item.sql

\ir quality/key_dm.well_day_balance.sql

\ir quality/key_dm.field_month_performance.sql

\ir quality/key_dm.repair_cost_month.sql

\ir quality/key_dm.energy_intensity_day.sql

\ir quality/key_dm.quality_compliance_day.sql

\ir quality/key_dm.shipment_balance_month.sql

\ir quality/key_dm.service_production_impact.sql

\ir quality/key_ctl.load_batch.sql

\ir quality/key_ctl.task_run.sql

\ir quality/key_ctl.quality_result.sql

\ir quality/key_ctl.source_asset.sql

\ir quality/key_ctl.publication_release.sql

\ir quality/relation_0_ods.og_tbl_production_volume.sql

\ir quality/relation_1_ods.og_tbl_well.sql

\ir quality/relation_2_ods.og_tbl_equipment_repair.sql

\ir quality/relation_3_ods.og_tbl_well_incident.sql

\ir quality/relation_4_ods.og_tbl_workrecord.sql

\ir quality/relation_5_ods.og_tbl_workrecord.sql

\ir quality/relation_6_ods.og_tbl_servicecall.sql

\ir quality/relation_7_ods.og_tbl_servicecall.sql

\ir quality/relation_8_ods.og_tbl_servicecall.sql

\ir quality/relation_9_ods.og_tbl_servicecall.sql

\ir quality/relation_10_ods.og_tbl_servicecall.sql

\ir quality/relation_11_ods.og_tbl_comment.sql

\ir quality/relation_12_ods.og_task.sql

\ir quality/relation_13_ods.og_task.sql

\ir quality/relation_14_ods.og_pa0001.sql

\ir quality/relation_15_stg.measurement_event.sql

\ir quality/relation_16_stg.repair_event.sql

\ir quality/relation_17_stg.lab_event.sql

\ir quality/relation_18_dds.dim_well_scd2.sql

\ir quality/relation_19_dds.bridge_equipment_well_history.sql

\ir quality/relation_20_dds.fact_production_day.sql

\ir quality/relation_21_dds.fact_telemetry_hour.sql

\ir quality/relation_22_dds.fact_downtime_interval.sql

\ir quality/relation_23_dds.fact_repair_order.sql

\ir quality/relation_24_dds.fact_repair_operation.sql

\ir quality/relation_25_dds.fact_energy_day.sql

\ir quality/relation_26_dds.fact_lab_sample.sql

\ir quality/relation_27_dds.fact_quality_measurement.sql

\ir quality/relation_28_dds.fact_production_plan_month.sql

\ir quality/relation_29_dm.well_day_balance.sql

\ir quality/relation_30_dm.repair_cost_month.sql

\ir quality/relation_31_dm.energy_intensity_day.sql

\ir quality/relation_32_dm.service_production_impact.sql

\ir quality/relation_33_dds.fact_production_day.sql

\ir quality/relation_34_dds.fact_repair_operation.sql

\ir quality/relation_35_dds.fact_quality_measurement.sql

\ir quality/relation_36_dds.fact_quality_measurement.sql

\ir quality/relation_37_dds.fact_energy_day.sql

\ir quality/relation_38_dds.fact_shipment_item.sql

\ir quality/daily_expected_count.sql

\ir quality/telemetry_expected_count.sql

\ir quality/daily_month_exact_decimal.sql

\ir quality/daily_source_double_tolerance.sql

\ir quality/scd_overlap.sql

\ir quality/scd_fact_one_version.sql

\ir quality/downtime_overlap.sql

\ir quality/hours_bounds.sql

\ir quality/energy_price.sql

\ir quality/zero_denominator_null.sql

\ir quality/plan_daily_month_conservation.sql

\ir quality/shipment_mass_balance.sql

\ir quality/shipment_month_continuity.sql

\ir quality/quality_flags_correct.sql

\ir quality/mart_aggregate_parity.sql

\ir quality/default_partitions_empty.sql

\ir quality/telemetry_utc_range.sql

\ir quality/raw_telemetry_count.sql

\ir quality/raw_json_parse.sql
