-- Allocate original monthly numerical totals to daily micro-units, retaining exact rounded totals.
CREATE TEMP TABLE production_weights ON COMMIT DROP AS
SELECT
    p.id AS source_month_id, p.well_id, c.business_date, round(p.oil_volume::numeric, 6) AS oil_month, round(p.gas_volume::numeric, 6) AS gas_month, round(p.water_volume::numeric, 6) AS water_month, (24 - coalesce(sum(
                CASE WHEN x.downtime_id IS NOT NULL THEN
                    extract(epoch FROM least (x.ends_at, c.business_date::timestamp + interval '1 day') - greatest (x.starts_at, c.business_date::timestamp)) / 3600
                ELSE
                    0
                END), 0))::numeric(8, 3) AS operating_hours
FROM
    ods.og_tbl_production_volume p
    JOIN ref.calendar c ON date_trunc('month', p.prod_date)::date = c.month_start
    LEFT JOIN dds.fact_downtime_interval x ON x.well_id = p.well_id
        AND x.starts_at < c.business_date::timestamp + interval '1 day'
        AND x.ends_at > c.business_date::timestamp
GROUP BY
    p.id, p.well_id, c.business_date, p.oil_volume, p.gas_volume, p.water_volume DISTRIBUTED BY
        (well_id);

