-- Prepared PL/pgSQL definition; not installed on the server.
CREATE FUNCTION etl.require_nonnegative(value numeric)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF value IS NULL OR value < 0 THEN
        RAISE EXCEPTION 'VALUE_MUST_BE_NONNEGATIVE';
    END IF;
    RETURN value;
END;
$$;
