-- Определяет SQL-представление oil_mart.v_field_production.
CREATE VIEW oil_mart.v_field_production AS
SELECT
    *
FROM
    oil_mart.agg_field_day;
