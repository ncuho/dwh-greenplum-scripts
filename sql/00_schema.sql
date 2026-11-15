-- Greenplum 6.26.2. New sng_dwh database only; existing DLH is read-only.

\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA ods;

CREATE SCHEMA mart;

CREATE SCHEMA ref;

CREATE SCHEMA stg;

CREATE SCHEMA dds;

CREATE SCHEMA dm;

CREATE SCHEMA ctl;

CREATE SCHEMA etl;

CREATE DOMAIN ref.tariff_rate AS numeric(12,6) CHECK (VALUE >= 0);

CREATE TYPE ref.work_state AS ENUM ('planned','running','done');

CREATE SEQUENCE ctl.run_id_seq START 1;

CREATE TABLE mart.bo_werks_text (
    "zkz_werks" text,
    "werks_name" text,
    "werks_text" text
) DISTRIBUTED BY (zkz_werks);

COMMENT ON TABLE mart.bo_werks_text IS 'Заводы (werks); synthetic demonstration, not production certification';

CREATE TABLE mart.dm_hse_incidents (
    "id" bigint,
    "locality_id" bigint,
    "year" bigint,
    "month" bigint,
    "incident_count" bigint,
    "severity_max" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_hse_incidents IS 'Витрина инцидентов HSE; synthetic demonstration, not production certification';

CREATE TABLE mart.dm_hse_one (
    "id" bigint,
    "incident_type" text,
    "severity" text,
    "timebegin" timestamp without time zone,
    "well_id" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_hse_one IS 'Витрина HSE (единая); synthetic demonstration, not production certification';

CREATE TABLE mart.dm_incidents (
    "id" bigint,
    "locality_name" text,
    "incident_count" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_incidents IS 'Витрина инцидентов; synthetic demonstration, not production certification';

CREATE TABLE mart.dm_project_status (
    "id" bigint,
    "director_id" bigint,
    "status" text,
    "project_count" bigint,
    "total_cost" double precision
) DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_project_status IS 'Витрина статусов проектов; synthetic demonstration, not production certification';

CREATE TABLE mart.dm_well (
    "id" bigint,
    "well_id" bigint,
    "well_state" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_well IS 'Витрина скважин; synthetic demonstration, not production certification';

CREATE TABLE mart.dm_well_more (
    "id" bigint,
    "well_id" bigint,
    "locality_name" text,
    "with_fire" text,
    "with_explode" text,
    "injuries" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_well_more IS 'Витрина скважин (расширенная); synthetic demonstration, not production certification';

CREATE TABLE mart.dm_well_production (
    "id" bigint,
    "well_id" bigint,
    "locality_id" bigint,
    "year" bigint,
    "month" bigint,
    "total_oil" double precision,
    "total_gas" double precision
) DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_well_production IS 'Витрина добычи по скважинам; synthetic demonstration, not production certification';

CREATE TABLE mart.sng_bs_area (
    "bs_area" text,
    "direction" text
) DISTRIBUTED BY (bs_area);

COMMENT ON TABLE mart.sng_bs_area IS 'Направления БС; synthetic demonstration, not production certification';

CREATE TABLE mart.sng_report (
    "id" bigint,
    "clientou_id" bigint,
    "year" bigint,
    "month" bigint,
    "cnt" bigint,
    "avg_resolution_min" double precision,
    "pct_usedkb" double precision,
    "pct_first_time" double precision,
    "avg_answer" double precision,
    "total_time_hours" double precision
) DISTRIBUTED BY (id);

COMMENT ON TABLE mart.sng_report IS 'Сводный отчёт по КПЭ (ОЕ × месяц); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_asu_work_assignment (
    "assigment_id" bigint,
    "assigment_name" text,
    "work_type" text,
    "assigment_state" text,
    "task_id" bigint,
    "executor_id" bigint
) DISTRIBUTED BY (assigment_id);

COMMENT ON TABLE ods.sng_asu_work_assignment IS 'Назначения работ; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_but000 (
    "partner" text,
    "type" text,
    "name_org1" text,
    "name_last" text,
    "name_first" text,
    "namemiddle" text,
    "ind_sector" text,
    "location_1" text,
    "found_dat" date
) DISTRIBUTED BY (partner);

COMMENT ON TABLE ods.sng_but000 IS 'Контрагенты (SAP BP); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_crmd_activity_h (
    "id" bigint,
    "category" text,
    "priority" text,
    "partner" text,
    "completion" boolean
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_crmd_activity_h IS 'CRM-активности; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_crmd_orderadm_h (
    "object_id" text,
    "process_type" text,
    "posting_date" date,
    "description" text,
    "partner" text
) DISTRIBUTED BY (object_id);

COMMENT ON TABLE ods.sng_crmd_orderadm_h IS 'Заказы (шапка); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_crmd_orderadm_i (
    "id" bigint,
    "ordered_prod" text,
    "header" text,
    "number_int" text,
    "cost" double precision
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_crmd_orderadm_i IS 'Позиции заказов; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_crmd_partner (
    "id" bigint,
    "partner_fct" text,
    "partner_no" text,
    "order_id" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_crmd_partner IS 'Партнёры заказов; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_pa0001 (
    "pernr" bigint,
    "bukrs" text,
    "werks" text,
    "orgeh" text,
    "stell" text
) DISTRIBUTED BY (pernr);

COMMENT ON TABLE ods.sng_pa0001 IS 'Штатная расстановка (SAP HR); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_pa0002 (
    "pernr" bigint,
    "nachn" text,
    "vorna" text,
    "midnm" text,
    "gesch" text,
    "gbdat" date,
    "natio" text
) DISTRIBUTED BY (pernr);

COMMENT ON TABLE ods.sng_pa0002 IS 'Личные данные (SAP HR); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_project (
    "id" bigint,
    "name" text,
    "code" text,
    "status_id" text,
    "director_id" bigint,
    "date_start_plan" date,
    "date_end_plan" date,
    "object_cost" double precision
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_project IS 'Проекты; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_t500p (
    "persa" text,
    "molga" text,
    "name1" text
) DISTRIBUTED BY (persa);

COMMENT ON TABLE ods.sng_t500p IS 'Персонал-области; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_task (
    "task_id" bigint,
    "task_title" text,
    "task_desc" text,
    "task_hours" double precision,
    "task_project_id" bigint,
    "task_status_id" bigint,
    "assigned_ws_user_id" bigint,
    "task_priority_id" bigint,
    "task_target_finish" timestamp without time zone,
    "task_completed" timestamp without time zone
) DISTRIBUTED BY (task_id);

COMMENT ON TABLE ods.sng_task IS 'Задачи проектов; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_changerequest (
    "id" bigint,
    "title" text,
    "state" text,
    "responsibleemployee_id" bigint,
    "responsibleteam_id" bigint,
    "impact" text,
    "category" text,
    "code" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_changerequest IS 'Запросы на изменения (Change Management); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_cmdb (
    "id" bigint,
    "title" text,
    "ci_hostname" text,
    "ci_ip" text,
    "state" text,
    "responsibleteam_id" bigint,
    "ci_bservice" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_cmdb IS 'Конфигурационные единицы; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_comment (
    "id" bigint,
    "servicecall_id" bigint,
    "author_id" bigint,
    "text" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_comment IS 'Комментарии; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_company (
    "id" bigint,
    "dbid" text,
    "fullname" text,
    "company_type" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_company IS 'Компании-подрядчики; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_directory (
    "id" bigint,
    "title" text,
    "code" text,
    "type" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_directory IS 'Справочник объектов; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_employee (
    "id" bigint,
    "first_name" text,
    "last_name" text,
    "middle_name" text,
    "fio" text,
    "login" text,
    "email" text,
    "mobile_phone" text,
    "employee_employeenumber" text,
    "post" text,
    "parent_id" bigint,
    "date_of_birth" timestamp without time zone
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_employee IS 'Сотрудники; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_equipment_repair (
    "id" bigint,
    "factbegindate" timestamp without time zone,
    "factenddate" timestamp without time zone,
    "wellid" bigint,
    "contractor_id" bigint,
    "cost" double precision
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_equipment_repair IS 'Ремонты оборудования; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_kb (
    "id" bigint,
    "title" text,
    "responsibleteam_id" bigint,
    "author_id" bigint,
    "viewcounter" bigint,
    "state" text,
    "kbsection_basedcateg" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_kb IS 'База знаний; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_locality (
    "id" bigint,
    "dbid" text,
    "name" text,
    "region" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_locality IS 'Месторождения (нефтегазовые); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_mark (
    "id" bigint,
    "code" text,
    "color" text,
    "title" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_mark IS 'Отметки; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_ou (
    "id" bigint,
    "title" text,
    "titleshort" text,
    "ou_code" text,
    "ou_customer" boolean,
    "parent_id" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_ou IS 'Организационные единицы (заказчики); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_priority (
    "id" bigint,
    "title" text,
    "priority_level" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_priority IS 'Приоритеты заявок; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_production_volume (
    "id" bigint,
    "well_id" bigint,
    "prod_date" date,
    "oil_volume" double precision,
    "gas_volume" double precision,
    "water_volume" double precision
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_production_volume IS 'Добыча (факт); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_servicecall (
    "id" bigint,
    "request_date" timestamp without time zone,
    "registration_date" timestamp without time zone,
    "state" text,
    "priority_id" bigint,
    "service_id" bigint,
    "clientou_id" bigint,
    "clientemployee_id" bigint,
    "responsibleteam_id" bigint,
    "responsibleemployee_id" bigint,
    "resolutiontime" bigint,
    "datedecision" timestamp without time zone,
    "usedkb" bigint,
    "cnt_sol" bigint,
    "answ_avg" bigint,
    "call_infsystem" bigint,
    "impact" text,
    "urgency" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_servicecall IS 'Заявки (факт); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_servicecateg (
    "id" bigint,
    "title" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_servicecateg IS 'Категории услуг; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_slmservice (
    "id" bigint,
    "title" text,
    "state_" text,
    "responsibleteam_id" bigint,
    "customer_ou" bigint,
    "classification" text,
    "rating" double precision,
    "informsystem" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_slmservice IS 'SLA-сервисы; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_team (
    "id" bigint,
    "title" text,
    "teamlevel" bigint,
    "leader_id" bigint,
    "headou_id" bigint
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_team IS 'Группы поддержки; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_typeworks (
    "id" bigint,
    "title" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_typeworks IS 'Виды работ; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_well (
    "id" bigint,
    "fieldid" bigint,
    "title" text,
    "depth" double precision,
    "state" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_well IS 'Скважины; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_well_incident (
    "id" bigint,
    "well_id" bigint,
    "timebegin" timestamp without time zone,
    "incident_type" text,
    "severity" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_well_incident IS 'Инциденты на скважинах (HSE); synthetic demonstration, not production certification';

CREATE TABLE ods.sng_tbl_workrecord (
    "id" bigint,
    "servicecall" bigint,
    "employee" bigint,
    "workrecordkb_typeworks" bigint,
    "time" double precision,
    "client_ou" bigint,
    "state" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_tbl_workrecord IS 'Записи работ; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_ws_user (
    "ws_user_id" bigint,
    "auth_user" text,
    "firstname" text,
    "lastname" text,
    "email" text,
    "phone_number" text,
    "job_title" text
) DISTRIBUTED BY (ws_user_id);

COMMENT ON TABLE ods.sng_ws_user IS 'Пользователи системы; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_zcbap_infsys (
    "id" bigint,
    "name" text,
    "short_name" text,
    "teh_name" text,
    "flag_cap" text
) DISTRIBUTED BY (id);

COMMENT ON TABLE ods.sng_zcbap_infsys IS 'Информационные системы; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_zgr_it (
    "kod_gr" text,
    "name" text,
    "name_eng" text,
    "gr_pp" text
) DISTRIBUTED BY (kod_gr);

COMMENT ON TABLE ods.sng_zgr_it IS 'Группы ИТ; synthetic demonstration, not production certification';

CREATE TABLE ods.sng_znapr (
    "kod_napr" text,
    "name" text,
    "name_eng" text
) DISTRIBUTED BY (kod_napr);

COMMENT ON TABLE ods.sng_znapr IS 'Направления деятельности; synthetic demonstration, not production certification';

CREATE TABLE ref.unit (
    "unit_code" text NOT NULL,
    "symbol" text,
    "description" text,
    "physical" boolean,
    PRIMARY KEY ("unit_code")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.unit IS 'One declared measure unit; synthetic demonstration, not production certification';

CREATE TABLE ref.calendar (
    "business_date" date NOT NULL,
    "year_no" integer,
    "month_no" integer,
    "month_start" date,
    "day_of_month" integer,
    "days_in_month" integer,
    "is_weekend" boolean,
    PRIMARY KEY ("business_date")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.calendar IS 'One business date in 2025; synthetic demonstration, not production certification';

CREATE TABLE ref.product (
    "product_id" integer NOT NULL,
    "product_code" text,
    "product_name" text,
    "unit_code" text,
    "contract_scope" text,
    PRIMARY KEY ("product_id")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.product IS 'One new synthetic commodity; synthetic demonstration, not production certification';

CREATE TABLE ref.repair_type (
    "repair_type_id" integer NOT NULL,
    "code" text,
    "description" text,
    "standard_hours" numeric(10,2),
    PRIMARY KEY ("repair_type_id")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.repair_type IS 'One repair activity type; synthetic demonstration, not production certification';

CREATE TABLE ref.downtime_reason (
    "reason_id" integer NOT NULL,
    "code" text,
    "planned" boolean,
    "description" text,
    PRIMARY KEY ("reason_id")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.downtime_reason IS 'One mutually classified reason; synthetic demonstration, not production certification';

CREATE TABLE ref.sensor_type (
    "sensor_type_id" integer NOT NULL,
    "code" text,
    "unit_code" text,
    "min_valid" numeric(18,6),
    "max_valid" numeric(18,6),
    PRIMARY KEY ("sensor_type_id")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.sensor_type IS 'One measured telemetry feature; synthetic demonstration, not production certification';

CREATE TABLE ref.energy_tariff (
    "tariff_id" integer NOT NULL,
    "valid_from" date,
    "valid_to" date,
    "rub_per_kwh" ref.tariff_rate,
    "currency_code" text,
    PRIMARY KEY ("tariff_id")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.energy_tariff IS 'One tariff and half-open effective interval; synthetic demonstration, not production certification';

CREATE TABLE ref.quality_spec (
    "spec_id" integer NOT NULL,
    "product_id" integer,
    "analyte" text,
    "unit_code" text,
    "min_value" numeric(18,6),
    "max_value" numeric(18,6),
    "valid_from" date,
    "valid_to" date,
    PRIMARY KEY ("spec_id")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.quality_spec IS 'One product/analyte/effective specification; synthetic demonstration, not production certification';

CREATE TABLE stg.measurement_event (
    "ingest_id" bigint NOT NULL,
    "source_event_key" text,
    "well_id" bigint,
    "event_ts" timestamp,
    "payload" json,
    "batch_id" bigint
) WITH (appendonly=true,orientation=row,compresstype=zlib,compresslevel=3) DISTRIBUTED RANDOMLY;

COMMENT ON TABLE stg.measurement_event IS 'One received hourly observation envelope; synthetic demonstration, not production certification';

CREATE TABLE stg.repair_event (
    "ingest_id" bigint NOT NULL,
    "source_event_key" text,
    "well_id" bigint,
    "event_ts" timestamp,
    "payload" json,
    "batch_id" bigint
) WITH (appendonly=true,orientation=row,compresstype=zlib,compresslevel=3) DISTRIBUTED RANDOMLY;

COMMENT ON TABLE stg.repair_event IS 'One incoming repair operation envelope; synthetic demonstration, not production certification';

CREATE TABLE stg.lab_event (
    "ingest_id" bigint NOT NULL,
    "source_event_key" text,
    "well_id" bigint,
    "event_ts" timestamp,
    "payload" json,
    "batch_id" bigint
) WITH (appendonly=true,orientation=row,compresstype=zlib,compresslevel=3) DISTRIBUTED RANDOMLY;

COMMENT ON TABLE stg.lab_event IS 'One laboratory result envelope; synthetic demonstration, not production certification';

CREATE TABLE stg.shipment_event (
    "ingest_id" bigint NOT NULL,
    "source_event_key" text,
    "locality_id" bigint,
    "event_ts" timestamp,
    "payload" json,
    "batch_id" bigint
) WITH (appendonly=true,orientation=row,compresstype=zlib,compresslevel=3) DISTRIBUTED RANDOMLY;

COMMENT ON TABLE stg.shipment_event IS 'One custody transfer envelope; synthetic demonstration, not production certification';

CREATE TABLE dds.dim_well_scd2 (
    "well_sk" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "locality_id" bigint,
    "valid_from" date,
    "valid_to" date,
    "pump_mode" text,
    "nominal_load_kw" numeric(12,3),
    "is_current" boolean,
    PRIMARY KEY ("well_id","well_sk")
) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.dim_well_scd2 IS 'One well attribute version [valid_from,valid_to); synthetic demonstration, not production certification';

CREATE TABLE dds.dim_equipment (
    "equipment_id" bigint NOT NULL,
    "equipment_code" text,
    "equipment_type" text,
    "commissioned_on" date,
    "rated_kw" numeric(12,3),
    PRIMARY KEY ("equipment_id")
) DISTRIBUTED BY (equipment_id);

COMMENT ON TABLE dds.dim_equipment IS 'One synthetic installed unit; synthetic demonstration, not production certification';

CREATE TABLE dds.dim_contract (
    "contract_id" bigint NOT NULL,
    "contractor_company_id" bigint,
    "valid_from" date,
    "valid_to" date,
    "hour_rate_rub" numeric(14,2),
    "currency_code" text,
    PRIMARY KEY ("contract_id")
) DISTRIBUTED BY (contract_id);

COMMENT ON TABLE dds.dim_contract IS 'One synthetic contractor agreement; synthetic demonstration, not production certification';

CREATE TABLE dds.bridge_equipment_well_history (
    "well_id" bigint NOT NULL,
    "equipment_id" bigint NOT NULL,
    "valid_from" date NOT NULL,
    "valid_to" date,
    PRIMARY KEY ("well_id","equipment_id","valid_from")
) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.bridge_equipment_well_history IS 'One equipment installation interval; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_production_day (
    "well_id" bigint NOT NULL,
    "business_date" date NOT NULL,
    "well_sk" bigint,
    "source_month_id" bigint,
    "oil_legacy_quantity" numeric(24,6),
    "gas_legacy_quantity" numeric(24,6),
    "water_legacy_quantity" numeric(24,6),
    "operating_hours" numeric(8,3),
    "contract_code" text,
    "batch_id" bigint
) WITH (appendonly=true,orientation=column,compresstype=zlib,compresslevel=3) DISTRIBUTED BY (well_id) PARTITION BY RANGE (business_date) (START (DATE '2025-01-01') END (DATE '2026-01-01') EVERY (INTERVAL '1 month'), DEFAULT PARTITION outside_period);

COMMENT ON TABLE dds.fact_production_day IS 'One well/business date reconciled to original month; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_telemetry_hour (
    "well_id" bigint NOT NULL,
    "event_ts" timestamp NOT NULL,
    "well_sk" bigint,
    "pressure_kpa" numeric(12,3),
    "temperature_c" numeric(8,3),
    "vibration_mm_s" numeric(8,4),
    "water_cut_pct" numeric(7,3),
    "quality_flag" text,
    "batch_id" bigint
) WITH (appendonly=true,orientation=column,compresstype=zlib,compresslevel=3) DISTRIBUTED BY (well_id) PARTITION BY RANGE (event_ts) (START (TIMESTAMP '2025-01-01') END (TIMESTAMP '2026-01-01') EVERY (INTERVAL '1 month'), DEFAULT PARTITION outside_period);

COMMENT ON TABLE dds.fact_telemetry_hour IS 'One well/hour; four physical synthetic sensors; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_downtime_interval (
    "downtime_id" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "starts_at" timestamp,
    "ends_at" timestamp,
    "reason_id" integer,
    "repair_order_id" bigint,
    "planned" boolean,
    "batch_id" bigint,
    PRIMARY KEY ("well_id","downtime_id")
) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_downtime_interval IS 'One non-overlapping well downtime interval; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_repair_order (
    "repair_order_id" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "equipment_id" bigint,
    "contract_id" bigint,
    "repair_type_id" integer,
    "opened_at" timestamp,
    "closed_at" timestamp,
    "status" ref.work_state,
    "source_repair_id" bigint,
    "batch_id" bigint,
    PRIMARY KEY ("well_id","repair_order_id")
) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_repair_order IS 'One new repair order (not a clone of source repair); synthetic demonstration, not production certification';

CREATE TABLE dds.fact_repair_operation (
    "operation_id" bigint NOT NULL,
    "repair_order_id" bigint,
    "well_id" bigint NOT NULL,
    "operation_code" text,
    "labor_hours" numeric(12,3),
    "material_cost_rub" numeric(18,2),
    "labor_cost_rub" numeric(18,2),
    "batch_id" bigint
) WITH (appendonly=true,orientation=row,compresstype=zlib,compresslevel=3) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_repair_operation IS 'One work operation within repair; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_energy_day (
    "well_id" bigint NOT NULL,
    "business_date" date NOT NULL,
    "tariff_id" integer,
    "energy_kwh" numeric(20,6),
    "energy_cost_rub" numeric(20,2),
    "batch_id" bigint
) WITH (appendonly=true,orientation=column,compresstype=zlib,compresslevel=3) DISTRIBUTED BY (well_id) PARTITION BY RANGE (business_date) (START (DATE '2025-01-01') END (DATE '2026-01-01') EVERY (INTERVAL '1 month'), DEFAULT PARTITION outside_period);

COMMENT ON TABLE dds.fact_energy_day IS 'One well/day electricity bill allocation; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_lab_sample (
    "sample_id" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "sampled_at" timestamp,
    "product_id" integer,
    "laboratory_code" text,
    "batch_id" bigint,
    PRIMARY KEY ("well_id","sample_id")
) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_lab_sample IS 'One well/month physical sample; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_quality_measurement (
    "well_id" bigint NOT NULL,
    "sample_id" bigint NOT NULL,
    "analyte" text NOT NULL,
    "measured_value" numeric(18,6),
    "unit_code" text,
    "spec_id" integer,
    "is_compliant" boolean,
    "batch_id" bigint
) WITH (appendonly=true,orientation=row,compresstype=zlib,compresslevel=3) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_quality_measurement IS 'One analyte result per sample; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_production_plan_month (
    "well_id" bigint NOT NULL,
    "month_start" date NOT NULL,
    "scenario" text NOT NULL,
    "oil_plan_legacy" numeric(24,6),
    "gas_plan_legacy" numeric(24,6),
    "energy_budget_kwh" numeric(20,6),
    "batch_id" bigint,
    PRIMARY KEY ("well_id","month_start","scenario")
) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dds.fact_production_plan_month IS 'One well/month/scenario plan; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_shipment (
    "shipment_id" bigint NOT NULL,
    "locality_id" bigint NOT NULL,
    "dispatched_at" timestamp,
    "buyer_contract_code" text,
    "transport_mode" text,
    "document_status" text,
    "batch_id" bigint,
    PRIMARY KEY ("locality_id","shipment_id")
) DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dds.fact_shipment IS 'One field dispatch document in independent physical scenario; synthetic demonstration, not production certification';

CREATE TABLE dds.fact_shipment_item (
    "locality_id" bigint NOT NULL,
    "shipment_id" bigint NOT NULL,
    "line_no" integer NOT NULL,
    "product_id" integer,
    "quantity_m3" numeric(20,6),
    "density_kg_m3" numeric(12,6),
    "amount_rub" numeric(20,2),
    "batch_id" bigint
) WITH (appendonly=true,orientation=row,compresstype=zlib,compresslevel=3) DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dds.fact_shipment_item IS 'One product line of dispatch; synthetic demonstration, not production certification';

CREATE TABLE dm.well_day_balance (
    "well_id" bigint NOT NULL,
    "business_date" date NOT NULL,
    "locality_id" bigint,
    "oil_legacy_quantity" numeric(24,6),
    "plan_oil_legacy" numeric(24,6),
    "lost_quantity_proxy" numeric(24,6),
    "downtime_hours" numeric(8,3),
    "energy_kwh" numeric(20,6),
    "energy_cost_rub" numeric(20,2),
    "run_id" bigint
) WITH (appendonly=true,orientation=column,compresstype=zlib,compresslevel=3) DISTRIBUTED BY (well_id) PARTITION BY RANGE (business_date) (START (DATE '2025-01-01') END (DATE '2026-01-01') EVERY (INTERVAL '1 month'), DEFAULT PARTITION outside_period);

COMMENT ON TABLE dm.well_day_balance IS 'One well/day; production energy downtime and loss proxy; synthetic demonstration, not production certification';

CREATE TABLE dm.field_month_performance (
    "locality_id" bigint NOT NULL,
    "month_start" date NOT NULL,
    "oil_actual_legacy" numeric(24,6),
    "oil_plan_legacy" numeric(24,6),
    "plan_attainment_pct" numeric(12,6),
    "energy_cost_rub" numeric(20,2),
    "downtime_hours" numeric(18,3),
    "run_id" bigint,
    PRIMARY KEY ("locality_id","month_start")
) DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dm.field_month_performance IS 'One locality/month; synthetic demonstration, not production certification';

CREATE TABLE dm.repair_cost_month (
    "well_id" bigint NOT NULL,
    "month_start" date NOT NULL,
    "repair_count" bigint,
    "labor_hours" numeric(18,3),
    "labor_cost_rub" numeric(20,2),
    "material_cost_rub" numeric(20,2),
    "run_id" bigint,
    PRIMARY KEY ("well_id","month_start")
) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dm.repair_cost_month IS 'One well/month repair expense; synthetic demonstration, not production certification';

CREATE TABLE dm.energy_intensity_day (
    "well_id" bigint NOT NULL,
    "business_date" date NOT NULL,
    "energy_kwh" numeric(20,6),
    "oil_legacy_quantity" numeric(24,6),
    "kwh_per_legacy_unit" numeric(24,6),
    "run_id" bigint
) WITH (appendonly=true,orientation=column,compresstype=zlib,compresslevel=3) DISTRIBUTED BY (well_id) PARTITION BY RANGE (business_date) (START (DATE '2025-01-01') END (DATE '2026-01-01') EVERY (INTERVAL '1 month'), DEFAULT PARTITION outside_period);

COMMENT ON TABLE dm.energy_intensity_day IS 'One well/day including undefined zero-production intensity; synthetic demonstration, not production certification';

CREATE TABLE dm.quality_compliance_day (
    "locality_id" bigint NOT NULL,
    "sample_date" date NOT NULL,
    "analyte" text NOT NULL,
    "sample_count" bigint,
    "failed_count" bigint,
    "compliance_pct" numeric(10,4),
    "run_id" bigint,
    PRIMARY KEY ("locality_id","sample_date","analyte")
) DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dm.quality_compliance_day IS 'One field/sampleday/analyte; synthetic demonstration, not production certification';

CREATE TABLE dm.shipment_balance_month (
    "locality_id" bigint NOT NULL,
    "month_start" date NOT NULL,
    "product_id" integer NOT NULL,
    "opening_m3" numeric(24,6),
    "received_synthetic_m3" numeric(24,6),
    "dispatched_m3" numeric(24,6),
    "closing_m3" numeric(24,6),
    "revenue_rub" numeric(20,2),
    "run_id" bigint,
    PRIMARY KEY ("locality_id","month_start","product_id")
) DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dm.shipment_balance_month IS 'One field/month/product independent physical stock balance; synthetic demonstration, not production certification';

CREATE TABLE dm.service_production_impact (
    "servicecall_id" bigint NOT NULL,
    "well_id" bigint NOT NULL,
    "linked_date" date,
    "association_basis" text,
    "is_causal_evidence" boolean,
    "downtime_hours" numeric(10,3),
    "run_id" bigint,
    PRIMARY KEY ("servicecall_id","well_id")
) DISTRIBUTED BY (well_id);

COMMENT ON TABLE dm.service_production_impact IS 'One explicitly synthetic service-to-well linkage assessment; synthetic demonstration, not production certification';

CREATE TABLE ctl.load_batch (
    "batch_id" bigint NOT NULL,
    "source_system" text,
    "source_cut_ref" text,
    "seed" bigint,
    "started_at" timestamptz,
    "finished_at" timestamptz,
    "state" text,
    PRIMARY KEY ("batch_id")
) DISTRIBUTED BY (batch_id);

COMMENT ON TABLE ctl.load_batch IS 'One immutable input batch identity; synthetic demonstration, not production certification';

CREATE TABLE ctl.task_run (
    "run_id" bigint NOT NULL,
    "batch_id" bigint,
    "task_name" text,
    "attempt" integer,
    "started_at" timestamptz,
    "finished_at" timestamptz,
    "state" text,
    "output_rows" bigint,
    PRIMARY KEY ("run_id")
) DISTRIBUTED BY (run_id);

COMMENT ON TABLE ctl.task_run IS 'One task attempt in a batch; synthetic demonstration, not production certification';

CREATE TABLE ctl.quality_result (
    "result_id" bigint NOT NULL,
    "batch_id" bigint,
    "asset_name" text,
    "check_name" text,
    "error_count" bigint,
    "state" text,
    "checked_at" timestamptz,
    PRIMARY KEY ("result_id")
) DISTRIBUTED BY (result_id);

COMMENT ON TABLE ctl.quality_result IS 'One check result per batch/table; synthetic demonstration, not production certification';

CREATE TABLE ctl.source_asset (
    "asset_name" text NOT NULL,
    "source_fqn" text,
    "snapshot_id" text,
    "row_count" bigint,
    "schema_sha256" text,
    "captured_at" timestamptz,
    PRIMARY KEY ("asset_name")
) DISTRIBUTED REPLICATED;

COMMENT ON TABLE ctl.source_asset IS 'One source table snapshot definition; synthetic demonstration, not production certification';

CREATE TABLE ctl.publication_release (
    "release_id" bigint NOT NULL,
    "batch_id" bigint,
    "release_state" text,
    "artifact_ref" text,
    "created_at" timestamptz,
    "validation_passed" boolean,
    PRIMARY KEY ("release_id")
) DISTRIBUTED BY (release_id);

COMMENT ON TABLE ctl.publication_release IS 'One reviewed cross-table release manifest; synthetic demonstration, not production certification';

CREATE INDEX ix_equipment_code ON dds.dim_equipment (equipment_code);

CREATE INDEX ix_equipment_type_bitmap ON dds.dim_equipment USING bitmap (equipment_type);

COMMIT;
