SELECT
    result.well_id,
    result.month_start,
    result.oil_actual_legacy,
    result.oil_plan_legacy,
    result.oil_actual_legacy - result.oil_plan_legacy AS variance_legacy
FROM (
    WITH actual AS (
        SELECT
            well_id,
            date_trunc('month', business_date)::date AS month_start,
            sum(oil_legacy_quantity) AS oil_actual_legacy
        FROM dds.fact_production_day
        GROUP BY well_id, date_trunc('month', business_date)::date
    )
    SELECT
        actual.well_id,
        actual.month_start,
        actual.oil_actual_legacy,
        plan.oil_plan_legacy
    FROM actual
    LEFT JOIN dds.fact_production_plan_month AS plan
        ON plan.well_id = actual.well_id
        AND plan.month_start = actual.month_start
        AND plan.scenario = 'base'
) AS result
ORDER BY result.month_start, result.well_id;
