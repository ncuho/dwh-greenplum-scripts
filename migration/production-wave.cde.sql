-- REVIEW CANDIDATE ONLY; not executed on CedrusData.
-- Read-only inputs must already exist at one approved cut.
-- Template namespaces are intentionally distinct from existing ods/mart.
CREATE TABLE dlh.migration_sng_candidate_r20261115.well_day_balance
WITH (format='PARQUET',format_version=2,partitioning=ARRAY['month(business_date)']) AS
WITH base AS (
 SELECT p.well_id,p.business_date,w.fieldid AS locality_id,p.oil_legacy_quantity,
 CAST(CASE WHEN c.day_of_month=c.days_in_month
 THEN pl.oil_plan_legacy-round(pl.oil_plan_legacy/CAST(c.days_in_month AS DECIMAL(10,0)),6)*(c.days_in_month-1)
 ELSE round(pl.oil_plan_legacy/CAST(c.days_in_month AS DECIMAL(10,0)),6) END AS DECIMAL(24,6)) AS plan_oil_legacy,
 CAST(24-p.operating_hours AS DECIMAL(8,3)) AS downtime_hours,e.energy_kwh,e.energy_cost_rub
 FROM dlh.migration_sng_bronze_r20261115.dds_fact_production_day p
 JOIN dlh.migration_sng_bronze_r20261115.ods_sng_tbl_well w ON w.id=p.well_id
 JOIN dlh.migration_sng_bronze_r20261115.ref_calendar c ON c.business_date=p.business_date
 JOIN dlh.migration_sng_bronze_r20261115.dds_fact_production_plan_month pl
 ON pl.well_id=p.well_id AND pl.month_start=c.month_start AND pl.scenario='base'
 JOIN dlh.migration_sng_bronze_r20261115.dds_fact_energy_day e
 ON e.well_id=p.well_id AND e.business_date=p.business_date
)
SELECT *,CAST(greatest(plan_oil_legacy-oil_legacy_quantity,DECIMAL '0.000000') AS DECIMAL(24,6)) AS lost_quantity_proxy,
'candidate_r20261115' AS release_id FROM base;

CREATE TABLE dlh.migration_sng_candidate_r20261115.field_month_performance
WITH (format='PARQUET',format_version=2) AS
SELECT locality_id,CAST(date_trunc('month',business_date) AS DATE) AS month_start,
CAST(sum(oil_legacy_quantity) AS DECIMAL(24,6)) AS oil_actual_legacy,
CAST(sum(plan_oil_legacy) AS DECIMAL(24,6)) AS oil_plan_legacy,
CAST(100*sum(oil_legacy_quantity)/nullif(sum(plan_oil_legacy),DECIMAL '0.000000') AS DECIMAL(12,6)) AS plan_attainment_pct,
CAST(sum(energy_cost_rub) AS DECIMAL(20,2)) AS energy_cost_rub,
CAST(sum(downtime_hours) AS DECIMAL(18,3)) AS downtime_hours,
'candidate_r20261115' AS release_id
FROM dlh.migration_sng_candidate_r20261115.well_day_balance
GROUP BY locality_id,CAST(date_trunc('month',business_date) AS DATE);
-- Consumer cutover is intentionally absent: both candidates require independent parity checks.
