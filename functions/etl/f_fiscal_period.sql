CREATE FUNCTION etl.f_fiscal_period (p_date date)
    RETURNS text
    LANGUAGE sql
    IMMUTABLE STRICT
    AS $$
    SELECT
        to_char(p_date, 'YYYY-MM')
$$;

