-- Определяет SQL-представление oil_mart.v_field_performance.
CREATE VIEW oil_mart.v_field_performance AS
SELECT
    p.*,
    CAST(coalesce(d.downtime_hours, 0) AS numeric(20, 6)) AS downtime_hours
FROM
    oil_mart.agg_field_day p
    LEFT JOIN oil_mart.agg_field_downtime_day d ON d.production_date = p.production_date
        AND d.field_hk = p.field_hk;
