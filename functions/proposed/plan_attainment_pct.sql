-- Prepared definition; not installed. NULL or zero plan yields NULL.
CREATE FUNCTION etl.plan_attainment_pct(actual_value numeric, plan_value numeric)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT 100::numeric * actual_value / NULLIF(plan_value, 0);
$$;
