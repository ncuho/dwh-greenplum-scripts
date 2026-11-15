CREATE FUNCTION etl.f_count_asset (p_schema text, p_table text)
    RETURNS bigint
    LANGUAGE plpgsql
    VOLATILE
    AS $$
DECLARE
    n bigint;
BEGIN
    IF p_schema NOT IN ('ods', 'mart', 'ref', 'stg', 'dds', 'dm', 'ctl') OR p_table !~ '^[a-z][a-z0-9_]*$' THEN
        RAISE EXCEPTION 'ASSET_NOT_ALLOWLISTED';
    END IF;
    EXECUTE 'SELECT count(*) FROM ' || quote_ident(p_schema) || '.' || quote_ident(p_table) INTO n;
    RETURN n;
END;
$$;

