-- Deterministic synthetic enrichment of the exact existing mirrors. New sng_dwh only.
\set ON_ERROR_STOP on
BEGIN;
SET statement_timeout='240s';
SET TIME ZONE 'UTC';
INSERT INTO ref.unit VALUES
('legacy_unknown','legacy qty','Original synthetic quantity: physical unit not established',false),
('m3','m3','Independent synthetic cubic metres',true),('kPa','kPa','Pressure',true),
('degC','degC','Temperature',true),('mm_s','mm/s','Vibration velocity',true),
('pct','%','Percentage',true),('kWh','kWh','Energy',true),('RUB','RUB','Synthetic money',true),
('h','h','Hours',true),('kg_m3','kg/m3','Density',true),('mg_l','mg/l','Concentration',true),('min','min','Minutes',true);
INSERT INTO ref.calendar
SELECT d::date,extract(year FROM d)::int,extract(month FROM d)::int,date_trunc('month',d)::date,
extract(day FROM d)::int,extract(day FROM date_trunc('month',d)+interval '1 month'-interval '1 day')::int,
extract(isodow FROM d) IN(6,7)
FROM generate_series(timestamp '2025-01-01',timestamp '2025-12-31',interval '1 day') AS d;
INSERT INTO ref.product VALUES(1,'crude_oil','Synthetic crude oil','m3','Independent physical shipment scenario'),(2,'water','Synthetic produced water','m3','Independent quality sample scenario'),(3,'gas','Synthetic gas','m3','Independent physical scenario');
INSERT INTO ref.repair_type VALUES(1,'inspection','Planned inspection',4),(2,'pump','Pump service',8),(3,'electric','Electrical service',6),(4,'seal','Seal replacement',5),(5,'calibration','Sensor calibration',3),(6,'overhaul','Scheduled overhaul',24);
INSERT INTO ref.downtime_reason VALUES(1,'planned_repair',true,'Planned equipment maintenance'),(2,'pump_fault',false,'Synthetic pump fault'),(3,'power',false,'Synthetic power interruption'),(4,'inspection',true,'Inspection'),(5,'weather',false,'Synthetic weather stop'),(6,'test',true,'Scheduled test');
INSERT INTO ref.sensor_type VALUES(1,'pressure','kPa',0,40000),(2,'temperature','degC',-50,200),(3,'vibration','mm_s',0,50),(4,'water_cut','pct',0,100);
INSERT INTO ref.energy_tariff VALUES(1,'2025-01-01','2025-04-01',5.10,'RUB'),(2,'2025-04-01','2025-07-01',5.25,'RUB'),(3,'2025-07-01','2025-10-01',5.40,'RUB'),(4,'2025-10-01','2026-01-01',5.50,'RUB');
INSERT INTO ref.quality_spec VALUES
(1,1,'density','kg_m3',800,900,'2025-01-01','2026-01-01'),(2,1,'water','pct',0,1,'2025-01-01','2026-01-01'),(3,1,'salts','mg_l',0,100,'2025-01-01','2026-01-01'),
(4,2,'density','kg_m3',990,1100,'2025-01-01','2026-01-01'),(5,2,'oil','mg_l',0,100,'2025-01-01','2026-01-01'),(6,3,'water','pct',0,1,'2025-01-01','2026-01-01');
INSERT INTO ctl.load_batch VALUES(1,'existing_synthetic_sng','per_table_iceberg_snapshot_manifest_v1',20251115,current_timestamp,NULL,'BUILDING');
INSERT INTO dds.dim_well_scd2
SELECT w.id*10+v.n,w.id,w.fieldid,
CASE WHEN v.n=1 THEN date '2025-01-01' ELSE date '2025-07-01' END,
CASE WHEN v.n=1 THEN date '2025-07-01' ELSE date '2026-01-01' END,
CASE WHEN v.n=1 THEN 'baseline' ELSE 'efficient' END,40+(w.id%20)*2-v.n,v.n=2
FROM ods.sng_tbl_well w CROSS JOIN (VALUES(1),(2)) v(n);
INSERT INTO dds.dim_equipment SELECT w.id*10+e.n,'EQ-'||w.id||'-'||e.n,CASE WHEN e.n=1 THEN 'pump' ELSE 'meter' END,date '2020-01-01'+(w.id%365)::int,CASE WHEN e.n=1 THEN 45+(w.id%20)*2 ELSE 1 END
FROM ods.sng_tbl_well w CROSS JOIN(VALUES(1),(2)) e(n);
INSERT INTO dds.bridge_equipment_well_history SELECT w.id,w.id*10+e.n,date '2025-01-01',date '2026-01-01' FROM ods.sng_tbl_well w CROSS JOIN(VALUES(1),(2)) e(n);
WITH companies AS(SELECT id,row_number() OVER(ORDER BY id) AS rn,count(*) OVER() AS total FROM ods.sng_tbl_company)
INSERT INTO dds.dim_contract SELECT n,c.id,date '2025-01-01',date '2026-01-01',1500+(n%5)*200,'RUB' FROM generate_series(1,20) n JOIN companies c ON c.rn=(n-1)%c.total+1;
INSERT INTO dds.fact_repair_order
SELECT w.id*10+q.n,w.id,w.id*10+1,1+(w.id%20),1+(w.id%6),
timestamp '2025-01-10'+(q.n-1)*interval '3 months',
timestamp '2025-01-10'+(q.n-1)*interval '3 months'+CASE WHEN w.id%10=0 THEN interval '24 hours' ELSE interval '12 hours' END,
'done'::ref.work_state,NULL::bigint,1
FROM ods.sng_tbl_well w CROSS JOIN generate_series(1,4) q(n);
INSERT INTO dds.fact_downtime_interval
SELECT repair_order_id,well_id,opened_at,closed_at,CASE WHEN well_id%3=0 THEN 2 ELSE 1 END,repair_order_id,well_id%3<>0,1 FROM dds.fact_repair_order;
INSERT INTO dds.fact_repair_operation
SELECT r.repair_order_id*10+n,r.repair_order_id,r.well_id,CASE n WHEN 1 THEN 'inspect' WHEN 2 THEN 'replace' ELSE 'test' END,
(n+1)::numeric(12,3),n*1000+(r.well_id%10)*100,round((n+1)*c.hour_rate_rub,2),1
FROM dds.fact_repair_order r JOIN dds.dim_contract c ON c.contract_id=r.contract_id CROSS JOIN generate_series(1,3) n;
-- Allocate original monthly numerical totals to daily micro-units, retaining exact rounded totals.
CREATE TEMP TABLE production_weights ON COMMIT DROP AS
SELECT p.id AS source_month_id,p.well_id,c.business_date,
round(p.oil_volume::numeric,6) AS oil_month,round(p.gas_volume::numeric,6) AS gas_month,round(p.water_volume::numeric,6) AS water_month,
(24-coalesce(sum(CASE WHEN x.downtime_id IS NOT NULL THEN extract(epoch FROM least(x.ends_at,c.business_date::timestamp+interval '1 day')-greatest(x.starts_at,c.business_date::timestamp))/3600 ELSE 0 END),0))::numeric(8,3) AS operating_hours
FROM ods.sng_tbl_production_volume p JOIN ref.calendar c ON date_trunc('month',p.prod_date)::date=c.month_start
LEFT JOIN dds.fact_downtime_interval x ON x.well_id=p.well_id AND x.starts_at<c.business_date::timestamp+interval '1 day' AND x.ends_at>c.business_date::timestamp
GROUP BY p.id,p.well_id,c.business_date,p.oil_volume,p.gas_volume,p.water_volume DISTRIBUTED BY(well_id);
CREATE TEMP TABLE production_floors ON COMMIT DROP AS
SELECT *,trunc(oil_month*operating_hours/sum(operating_hours) OVER(PARTITION BY well_id,source_month_id),6) AS oil_floor,
trunc(gas_month*operating_hours/sum(operating_hours) OVER(PARTITION BY well_id,source_month_id),6) AS gas_floor,
trunc(water_month*operating_hours/sum(operating_hours) OVER(PARTITION BY well_id,source_month_id),6) AS water_floor,
max(CASE WHEN operating_hours>0 THEN business_date END) OVER(PARTITION BY well_id,source_month_id) AS residual_day
FROM production_weights DISTRIBUTED BY(well_id);
INSERT INTO dds.fact_production_day
SELECT f.well_id,f.business_date,s.well_sk,f.source_month_id,
f.oil_floor+CASE WHEN business_date=residual_day THEN oil_month-sum(oil_floor) OVER(PARTITION BY f.well_id,source_month_id) ELSE 0 END,
f.gas_floor+CASE WHEN business_date=residual_day THEN gas_month-sum(gas_floor) OVER(PARTITION BY f.well_id,source_month_id) ELSE 0 END,
f.water_floor+CASE WHEN business_date=residual_day THEN water_month-sum(water_floor) OVER(PARTITION BY f.well_id,source_month_id) ELSE 0 END,
operating_hours,'legacy_numeric_proxy_v1',1
FROM production_floors f JOIN dds.dim_well_scd2 s ON s.well_id=f.well_id AND f.business_date>=s.valid_from AND f.business_date<s.valid_to;
INSERT INTO dds.fact_energy_day
SELECT p.well_id,p.business_date,t.tariff_id,round(p.operating_hours*s.nominal_load_kw*(1+(p.well_id%7)::numeric/100),6),
round(p.operating_hours*s.nominal_load_kw*(1+(p.well_id%7)::numeric/100)*t.rub_per_kwh,2),1
FROM dds.fact_production_day p JOIN dds.dim_well_scd2 s ON s.well_id=p.well_id AND s.well_sk=p.well_sk
JOIN ref.energy_tariff t ON p.business_date>=t.valid_from AND p.business_date<t.valid_to;
INSERT INTO dds.fact_telemetry_hour
SELECT p.well_id,p.business_date::timestamp+h.n*interval '1 hour',p.well_sk,
12000+(p.well_id%40)*75+h.n*3,45+(p.well_id%15)+h.n::numeric/10,
CASE WHEN p.well_id%17=0 AND extract(month FROM p.business_date)=7 THEN 12 ELSE 2+(p.well_id%5)::numeric/10 END,
30+(p.well_id%50),CASE WHEN p.well_id%17=0 AND extract(month FROM p.business_date)=7 THEN 'synthetic_alert' ELSE 'valid' END,1
FROM dds.fact_production_day p CROSS JOIN generate_series(0,23) h(n);
INSERT INTO dds.fact_production_plan_month
SELECT p.well_id,date_trunc('month',p.prod_date)::date,s.scenario,
round(p.oil_volume::numeric*(CASE WHEN s.scenario='base' THEN 1.05 ELSE 1.10 END),6),
round(p.gas_volume::numeric*(CASE WHEN s.scenario='base' THEN 1.03 ELSE 1.07 END),6),
(c.days_in_month*24*(40+p.well_id%20*2))::numeric(20,6),1
FROM ods.sng_tbl_production_volume p JOIN ref.calendar c ON c.business_date=date_trunc('month',p.prod_date)::date CROSS JOIN(VALUES('base'),('stretch')) s(scenario);
INSERT INTO dds.fact_lab_sample SELECT p.well_id*100+extract(month FROM p.prod_date)::bigint,p.well_id,date_trunc('month',p.prod_date)+interval '15 days',1,'LAB-SYNTHETIC',1 FROM ods.sng_tbl_production_volume p;
INSERT INTO dds.fact_quality_measurement
SELECT s.well_id,s.sample_id,q.analyte,
CASE q.analyte WHEN 'density' THEN 840+s.well_id%30 WHEN 'water' THEN CASE WHEN s.well_id%19=0 THEN 1.5 ELSE 0.3 END ELSE 30+s.well_id%20 END,
q.unit_code,q.spec_id,NOT(q.analyte='water' AND s.well_id%19=0),1
FROM dds.fact_lab_sample s JOIN ref.quality_spec q ON q.product_id=s.product_id AND s.sampled_at>=q.valid_from AND s.sampled_at<q.valid_to;
INSERT INTO dds.fact_shipment
SELECT l.id*100+c.month_no,l.id,c.business_date::timestamp+interval '19 days','BUYER-SYNTHETIC-'||(l.id%4),'pipeline','accepted',1
FROM ods.sng_tbl_locality l JOIN ref.calendar c ON c.day_of_month=1;
INSERT INTO dds.fact_shipment_item SELECT locality_id,shipment_id,1,1,1000+(locality_id%10)*100,850,round((1000+(locality_id%10)*100)*35000,2),1 FROM dds.fact_shipment;
-- Raw envelopes are distinct landing contracts; source IDs remain traceable.
INSERT INTO stg.measurement_event
SELECT well_id*100000+(extract(doy FROM event_ts)::bigint-1)*24+extract(hour FROM event_ts)::bigint,'telemetry:'||well_id||':'||event_ts,well_id,event_ts,
json_build_object('pressure_kpa',pressure_kpa,'temperature_c',temperature_c,'vibration_mm_s',vibration_mm_s,'water_cut_pct',water_cut_pct),batch_id FROM dds.fact_telemetry_hour;
INSERT INTO stg.repair_event SELECT o.operation_id,'repair:'||o.operation_id,o.well_id,r.closed_at,json_build_object('order_id',o.repair_order_id,'operation',o.operation_code,'hours',o.labor_hours,'cost_rub',o.material_cost_rub+o.labor_cost_rub),o.batch_id FROM dds.fact_repair_operation o JOIN dds.fact_repair_order r ON r.well_id=o.well_id AND r.repair_order_id=o.repair_order_id;
INSERT INTO stg.lab_event SELECT m.sample_id*10+m.spec_id,'lab:'||m.sample_id||':'||m.analyte,m.well_id,s.sampled_at,json_build_object('analyte',m.analyte,'value',m.measured_value,'unit',m.unit_code),m.batch_id FROM dds.fact_quality_measurement m JOIN dds.fact_lab_sample s ON s.well_id=m.well_id AND s.sample_id=m.sample_id;
INSERT INTO stg.shipment_event SELECT shipment_id,'shipment:'||shipment_id,locality_id,dispatched_at,json_build_object('status',document_status,'transport',transport_mode),batch_id FROM dds.fact_shipment;
UPDATE ctl.load_batch SET state='ENRICHED',finished_at=current_timestamp WHERE batch_id=1;
COMMIT;
