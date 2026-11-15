CREATE FUNCTION etl.f_energy_cost (p_kwh numeric, p_rate ref.tariff_rate)
    RETURNS numeric
    LANGUAGE sql
    IMMUTABLE STRICT
    AS $$
    SELECT
        round(p_kwh * p_rate, 2)
$$;

