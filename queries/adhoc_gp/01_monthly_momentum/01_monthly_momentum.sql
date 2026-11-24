-- Считает месячную добычу и её изменение к предыдущему месяцу по месторождениям.
WITH monthly AS (
    SELECT date_trunc('month', production_date)::date AS month,
           field_name, sum(oil_tonnes) AS oil_tonnes
    FROM oil_mart.v_field_production
    WHERE production_date >= DATE '2025-01-01' AND production_date < DATE '2026-01-01'
    GROUP BY 1, 2
), compared AS (
    SELECT *, lag(oil_tonnes) OVER (PARTITION BY field_name ORDER BY month) AS previous_tonnes
    FROM monthly
)
SELECT month, field_name, oil_tonnes,
       round(100.0 * (oil_tonnes - previous_tonnes) / nullif(previous_tonnes, 0), 2) AS change_pct
FROM compared ORDER BY field_name, month;
