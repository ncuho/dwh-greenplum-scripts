CREATE FUNCTION etl.f_parse_telemetry (p_payload json)
    RETURNS TABLE (
        pressure_kpa numeric,
        temperature_c numeric,
        vibration_mm_s numeric,
        water_cut_pct numeric)
    LANGUAGE sql
    IMMUTABLE STRICT
    AS $$
    SELECT
        (p_payload ->> 'pressure_kpa')::numeric,
        (p_payload ->> 'temperature_c')::numeric,
        (p_payload ->> 'vibration_mm_s')::numeric,
        (p_payload ->> 'water_cut_pct')::numeric
$$;

