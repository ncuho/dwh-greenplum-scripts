\set ON_ERROR_STOP on
BEGIN;
CREATE FUNCTION etl.f_fiscal_period(p_date date) RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $$ SELECT to_char(p_date,'YYYY-MM') $$;
CREATE FUNCTION etl.f_energy_cost(p_kwh numeric,p_rate ref.tariff_rate) RETURNS numeric LANGUAGE sql IMMUTABLE STRICT AS $$ SELECT round(p_kwh*p_rate,2) $$;
CREATE FUNCTION etl.f_parse_telemetry(p_payload json) RETURNS TABLE(pressure_kpa numeric,temperature_c numeric,vibration_mm_s numeric,water_cut_pct numeric) LANGUAGE sql IMMUTABLE STRICT AS $$ SELECT (p_payload->>'pressure_kpa')::numeric,(p_payload->>'temperature_c')::numeric,(p_payload->>'vibration_mm_s')::numeric,(p_payload->>'water_cut_pct')::numeric $$;
CREATE FUNCTION etl.f_count_asset(p_schema text,p_table text) RETURNS bigint LANGUAGE plpgsql VOLATILE AS $$
DECLARE n bigint;
BEGIN
 IF p_schema NOT IN('ods','mart','ref','stg','dds','dm','ctl') OR p_table!~'^[a-z][a-z0-9_]*$' THEN RAISE EXCEPTION 'ASSET_NOT_ALLOWLISTED';END IF;
 EXECUTE 'SELECT count(*) FROM '||quote_ident(p_schema)||'.'||quote_ident(p_table) INTO n;
 RETURN n;
END;$$;
CREATE FUNCTION etl.rebuild_marts(p_batch_id bigint,p_run_id bigint) RETURNS bigint LANGUAGE plpgsql VOLATILE AS $$
DECLARE rows_written bigint;existing_batch bigint;
BEGIN
 IF p_batch_id IS NULL OR p_batch_id<>1 OR p_run_id IS NULL THEN RAISE EXCEPTION 'FIXED_SYNTHETIC_BATCH_REQUIRED';END IF;
 IF NOT EXISTS(SELECT 1 FROM ctl.load_batch WHERE batch_id=p_batch_id AND state IN('ENRICHED','VALIDATED')) THEN RAISE EXCEPTION 'BATCH_NOT_READY';END IF;
 LOCK TABLE ctl.task_run IN EXCLUSIVE MODE;
 SELECT batch_id INTO existing_batch FROM ctl.task_run WHERE run_id=p_run_id;
 IF existing_batch IS NOT NULL AND existing_batch<>p_batch_id THEN RAISE EXCEPTION 'RUN_ID_CONFLICT';END IF;
 IF (SELECT count(*) FROM dds.fact_production_day)<>(SELECT count(*) FROM ods.sng_tbl_well)*(SELECT count(*) FROM ref.calendar) THEN RAISE EXCEPTION 'INCOMPLETE_PRODUCTION';END IF;
 IF EXISTS(SELECT 1 FROM dds.fact_energy_day WHERE energy_kwh<0 OR energy_cost_rub<0) THEN RAISE EXCEPTION 'INVALID_ENERGY';END IF;
 IF EXISTS(SELECT 1 FROM dds.fact_production_day WHERE operating_hours<0 OR operating_hours>24) THEN RAISE EXCEPTION 'INVALID_OPERATING_HOURS';END IF;
 IF EXISTS(SELECT well_id,business_date FROM dds.fact_production_day GROUP BY 1,2 HAVING count(*)<>1) THEN RAISE EXCEPTION 'DUPLICATE_PRODUCTION_KEY';END IF;
 IF EXISTS(SELECT well_id,business_date FROM dds.fact_energy_day GROUP BY 1,2 HAVING count(*)<>1) THEN RAISE EXCEPTION 'DUPLICATE_ENERGY_KEY';END IF;
 CREATE TEMP TABLE work_well_balance ON COMMIT DROP AS
 SELECT p.well_id,p.business_date,w.fieldid AS locality_id,p.oil_legacy_quantity,
 (CASE WHEN c.day_of_month=c.days_in_month THEN pl.oil_plan_legacy-round(pl.oil_plan_legacy/c.days_in_month,6)*(c.days_in_month-1) ELSE round(pl.oil_plan_legacy/c.days_in_month,6) END) AS plan_oil_legacy,
 greatest((CASE WHEN c.day_of_month=c.days_in_month THEN pl.oil_plan_legacy-round(pl.oil_plan_legacy/c.days_in_month,6)*(c.days_in_month-1) ELSE round(pl.oil_plan_legacy/c.days_in_month,6) END)-p.oil_legacy_quantity,0)::numeric(24,6) AS lost_quantity_proxy,
 (24-p.operating_hours)::numeric(8,3) AS downtime_hours,e.energy_kwh,e.energy_cost_rub,p_run_id AS run_id
 FROM dds.fact_production_day p JOIN ods.sng_tbl_well w ON w.id=p.well_id
 JOIN ref.calendar c ON c.business_date=p.business_date
 JOIN dds.fact_production_plan_month pl ON pl.well_id=p.well_id AND pl.month_start=c.month_start AND pl.scenario='base'
 JOIN dds.fact_energy_day e ON e.well_id=p.well_id AND e.business_date=p.business_date
 DISTRIBUTED BY(well_id);
 SELECT count(*) INTO rows_written FROM work_well_balance;
 IF rows_written<>(SELECT count(*) FROM dds.fact_production_day) THEN RAISE EXCEPTION 'MART_JOIN_CARDINALITY';END IF;
 DELETE FROM dm.well_day_balance;
 INSERT INTO dm.well_day_balance SELECT * FROM work_well_balance;
 DELETE FROM dm.field_month_performance;
 INSERT INTO dm.field_month_performance
 SELECT b.locality_id,date_trunc('month',b.business_date)::date,sum(b.oil_legacy_quantity),sum(b.plan_oil_legacy),
 round(100*sum(b.oil_legacy_quantity)/nullif(sum(b.plan_oil_legacy),0),6),sum(b.energy_cost_rub),sum(b.downtime_hours),p_run_id
 FROM work_well_balance b GROUP BY b.locality_id,date_trunc('month',b.business_date)::date;
 DELETE FROM dm.repair_cost_month;
 INSERT INTO dm.repair_cost_month
 SELECT p.well_id,p.month_start,count(DISTINCT r.repair_order_id),coalesce(sum(o.labor_hours),0),coalesce(sum(o.labor_cost_rub),0),coalesce(sum(o.material_cost_rub),0),p_run_id
 FROM dds.fact_production_plan_month p LEFT JOIN dds.fact_repair_order r ON r.well_id=p.well_id AND date_trunc('month',r.closed_at)::date=p.month_start
 LEFT JOIN dds.fact_repair_operation o ON o.well_id=r.well_id AND o.repair_order_id=r.repair_order_id
 WHERE p.scenario='base' GROUP BY p.well_id,p.month_start;
 DELETE FROM dm.energy_intensity_day;
 INSERT INTO dm.energy_intensity_day SELECT well_id,business_date,energy_kwh,oil_legacy_quantity,round(energy_kwh/nullif(oil_legacy_quantity,0),6),p_run_id FROM work_well_balance;
 DELETE FROM dm.quality_compliance_day;
 INSERT INTO dm.quality_compliance_day SELECT w.fieldid,s.sampled_at::date,m.analyte,count(*),sum(CASE WHEN m.is_compliant THEN 0 ELSE 1 END),round(100*sum(CASE WHEN m.is_compliant THEN 1 ELSE 0 END)::numeric/count(*),4),p_run_id
 FROM dds.fact_quality_measurement m JOIN dds.fact_lab_sample s ON s.well_id=m.well_id AND s.sample_id=m.sample_id JOIN ods.sng_tbl_well w ON w.id=m.well_id GROUP BY w.fieldid,s.sampled_at::date,m.analyte;
 DELETE FROM dm.shipment_balance_month;
 INSERT INTO dm.shipment_balance_month
 SELECT s.locality_id,date_trunc('month',s.dispatched_at)::date,i.product_id,
 5000+(extract(month FROM s.dispatched_at)::int-1)*250, sum(i.quantity_m3)+250,sum(i.quantity_m3),
 5000+extract(month FROM s.dispatched_at)::int*250,sum(i.amount_rub),p_run_id
 FROM dds.fact_shipment s JOIN dds.fact_shipment_item i ON i.locality_id=s.locality_id AND i.shipment_id=s.shipment_id
 WHERE s.document_status='accepted' GROUP BY s.locality_id,date_trunc('month',s.dispatched_at)::date,i.product_id,extract(month FROM s.dispatched_at)::int;
 DELETE FROM dm.service_production_impact;
 INSERT INTO dm.service_production_impact
 SELECT c.id,w.id,date '2025-01-10','explicit synthetic ordinal association; not observed source relationship',false,
 coalesce(sum(24-p.operating_hours),0),p_run_id
 FROM (SELECT id,row_number() OVER(ORDER BY id) AS rn FROM ods.sng_tbl_servicecall) c
 JOIN (SELECT id,row_number() OVER(ORDER BY id) AS rn FROM ods.sng_tbl_well) w ON w.rn=c.rn
 LEFT JOIN dds.fact_production_day p ON p.well_id=w.id AND p.business_date=date '2025-01-10'
 GROUP BY c.id,w.id;
 DELETE FROM ctl.task_run WHERE run_id=p_run_id;
 INSERT INTO ctl.task_run VALUES(p_run_id,p_batch_id,'rebuild_marts',1,current_timestamp,current_timestamp,'COMPLETED',rows_written);
 DROP TABLE work_well_balance;
 RETURN rows_written;
END;$$;
CREATE VIEW dm.v_production_dashboard AS SELECT m.locality_id,l.name AS locality_name,m.month_start,m.oil_actual_legacy,m.oil_plan_legacy,m.plan_attainment_pct,m.energy_cost_rub,m.downtime_hours FROM dm.field_month_performance m JOIN ods.sng_tbl_locality l ON l.id=m.locality_id;
CREATE VIEW dds.v_production_with_well AS SELECT p.well_id,w.title,p.business_date,p.oil_legacy_quantity,p.gas_legacy_quantity,p.water_legacy_quantity,p.operating_hours FROM dds.fact_production_day p JOIN ods.sng_tbl_well w ON w.id=p.well_id;
COMMIT;
-- One coordinator-side call; function edits and audit commit together.
SELECT etl.rebuild_marts(1,nextval('ctl.run_id_seq'));
CREATE MATERIALIZED VIEW dm.mv_field_month_energy AS SELECT locality_id,month_start,sum(energy_cost_rub) AS energy_cost_rub FROM dm.field_month_performance GROUP BY locality_id,month_start DISTRIBUTED BY(locality_id);
REFRESH MATERIALIZED VIEW dm.mv_field_month_energy;
