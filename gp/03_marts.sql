-- One GP transaction per refresh. Requires an external single-writer fence.
CREATE OR REPLACE FUNCTION oil_mart.refresh_production() RETURNS void AS $$
DECLARE bad bigint;
BEGIN
 IF NOT pg_catalog.pg_try_advisory_xact_lock(860223191::bigint) THEN RAISE EXCEPTION 'oil source is fenced'; END IF;
 SELECT count(*) INTO bad FROM (
  SELECT field_hk,event_time FROM oil_dds.sat_field GROUP BY field_hk,event_time HAVING count(*)>1
  UNION ALL SELECT well_hk,(valid_from::timestamp AT TIME ZONE 'UTC') FROM oil_dds.sat_well GROUP BY well_hk,valid_from HAVING count(*)>1
 ) q;
 IF bad>0 THEN RAISE EXCEPTION 'ambiguous dimension effective dates %',bad; END IF;
 DELETE FROM oil_mart.fact_well_day;
 DELETE FROM oil_mart.agg_field_day;
 DELETE FROM oil_mart.dim_well;
 DELETE FROM oil_mart.dim_field;
 INSERT INTO oil_mart.dim_field
 SELECT field_hk,entity_version,event_time,lead(event_time) OVER(PARTITION BY field_hk ORDER BY event_time,entity_version),field_name,region,op='D' FROM oil_dds.sat_field;
 INSERT INTO oil_mart.dim_well
 SELECT w.well_hk,l.field_hk,w.entity_version,w.valid_from,lead(w.valid_from) OVER(PARTITION BY w.well_hk ORDER BY w.valid_from,w.entity_version),w.well_name,w.status,w.op='D'
 FROM oil_dds.sat_well w JOIN oil_dds.link_well_field l ON l.link_hk=w.link_hk;
 INSERT INTO oil_mart.fact_well_day
 SELECT p.production_hk,l.well_hk,w.field_hk,p.production_date,w.entity_version,f.entity_version,p.status,p.oil_tonnes
 FROM (SELECT *,row_number() OVER(PARTITION BY production_hk ORDER BY entity_version DESC,event_id DESC) rn FROM oil_dds.sat_daily_production) p
 JOIN oil_dds.link_production_day_well l ON l.link_hk=p.link_hk
 JOIN oil_mart.dim_well w ON w.well_hk=l.well_hk AND NOT w.is_deleted AND w.valid_from<=p.production_date AND (w.valid_to IS NULL OR p.production_date<w.valid_to)
 JOIN oil_mart.dim_field f ON f.field_hk=w.field_hk AND NOT f.is_deleted AND f.valid_from<=(p.production_date::timestamp AT TIME ZONE 'UTC') AND (f.valid_to IS NULL OR (p.production_date::timestamp AT TIME ZONE 'UTC')<f.valid_to)
 WHERE p.rn=1 AND p.op='U';
 SELECT count(*) INTO bad FROM (SELECT p.production_hk FROM (SELECT *,row_number() OVER(PARTITION BY production_hk ORDER BY entity_version DESC,event_id DESC) rn FROM oil_dds.sat_daily_production) p WHERE p.rn=1 AND p.op='U' AND (SELECT count(*) FROM oil_mart.fact_well_day f WHERE f.production_hk=p.production_hk)<>1) q;
 IF bad>0 THEN RAISE EXCEPTION 'missing or ambiguous production dimensions %',bad; END IF;
 SELECT count(*) INTO bad FROM oil_mart.fact_well_day p JOIN oil_mart.dim_well w ON p.well_hk=w.well_hk AND p.well_version=w.entity_version
 WHERE p.status<>w.status OR (p.status='INACTIVE' AND p.oil_tonnes<>0);
 IF bad>0 THEN RAISE EXCEPTION 'inconsistent well status / nonzero inactive oil %',bad; END IF;
 INSERT INTO oil_mart.agg_field_day
 SELECT p.production_date,p.field_hk,f.field_name,f.region,sum(p.oil_tonnes)::numeric(22,3),
  sum(CASE WHEN p.status='ACTIVE' THEN 1 ELSE 0 END)::bigint,
  CASE WHEN sum(CASE WHEN p.status='ACTIVE' THEN 1 ELSE 0 END)=0 THEN NULL ELSE
   (sum(p.oil_tonnes)/sum(CASE WHEN p.status='ACTIVE' THEN 1 ELSE 0 END))::numeric(22,6) END
 FROM oil_mart.fact_well_day p JOIN oil_mart.dim_field f ON f.field_hk=p.field_hk AND f.entity_version=p.field_version
 GROUP BY p.production_date,p.field_hk,f.field_name,f.region;
END; $$ LANGUAGE plpgsql;
-- Second independent business chain; run only after production refresh.
CREATE OR REPLACE FUNCTION oil_mart.refresh_downtime() RETURNS void AS $$
DECLARE bad bigint;
BEGIN
 IF NOT pg_catalog.pg_try_advisory_xact_lock(860223191::bigint) THEN RAISE EXCEPTION 'oil source is fenced'; END IF;
 DELETE FROM oil_mart.fact_downtime_interval;
 DELETE FROM oil_mart.agg_field_downtime_day;
 DELETE FROM oil_mart.dim_downtime_reason;
 INSERT INTO oil_mart.dim_downtime_reason VALUES ('EQUIPMENT','Оборудование'),('POWER','Энергоснабжение'),('PLANNED','Плановый простой');
 INSERT INTO oil_mart.fact_downtime_interval
 SELECT d.downtime_hk,l.well_hk,p.field_hk,d.start_at,d.end_at,d.reason,
   (extract(epoch FROM (d.end_at-d.start_at))/3600)::numeric(16,6)
 FROM (SELECT *,row_number() OVER(PARTITION BY downtime_hk ORDER BY entity_version DESC,event_id DESC) rn FROM oil_dds.sat_downtime) d
 JOIN oil_dds.link_downtime_well l ON l.link_hk=d.link_hk
 JOIN oil_mart.fact_well_day p ON p.well_hk=l.well_hk AND p.production_date=(d.start_at AT TIME ZONE 'UTC')::date AND p.status='ACTIVE'
 WHERE d.rn=1 AND d.op='U';
 SELECT count(*) INTO bad FROM (SELECT d.downtime_hk FROM (SELECT *,row_number() OVER(PARTITION BY downtime_hk ORDER BY entity_version DESC,event_id DESC) rn FROM oil_dds.sat_downtime) d WHERE d.rn=1 AND d.op='U' AND (SELECT count(*) FROM oil_mart.fact_downtime_interval f WHERE f.downtime_hk=d.downtime_hk)<>1) q;
 IF bad>0 THEN RAISE EXCEPTION 'downtime has no uniquely active well/day %',bad; END IF;
 SELECT count(*) INTO bad FROM oil_mart.fact_downtime_interval a JOIN oil_mart.fact_downtime_interval b ON a.well_hk=b.well_hk AND a.downtime_hk<b.downtime_hk AND a.start_at<b.end_at AND b.start_at<a.end_at;
 IF bad>0 THEN RAISE EXCEPTION 'overlapping downtime intervals %',bad; END IF;
 INSERT INTO oil_mart.agg_field_downtime_day
 SELECT (start_at AT TIME ZONE 'UTC')::date,field_hk,sum(hours)::numeric(20,6)
 FROM oil_mart.fact_downtime_interval GROUP BY 1,2;
END; $$ LANGUAGE plpgsql;
-- The first migration wave uses production only; the second adds downtime.
CREATE VIEW oil_mart.v_field_production AS SELECT * FROM oil_mart.agg_field_day;
CREATE VIEW oil_mart.v_field_performance AS
 SELECT p.*,CAST(coalesce(d.downtime_hours,0) AS numeric(20,6)) AS downtime_hours
 FROM oil_mart.agg_field_day p LEFT JOIN oil_mart.agg_field_downtime_day d
 ON d.production_date=p.production_date AND d.field_hk=p.field_hk;
