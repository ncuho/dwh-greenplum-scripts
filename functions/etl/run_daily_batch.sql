CREATE FUNCTION etl.run_daily_batch (p_batch_id bigint, p_from date, p_to date, p_run_id bigint)
    RETURNS bigint
    LANGUAGE plpgsql
    VOLATILE
    AS $$
DECLARE
    n bigint;
BEGIN
    n := etl.rebuild_production_day (p_from, p_to, p_batch_id);
    PERFORM
        etl.rebuild_marts (p_batch_id, p_run_id);
    RETURN n;
END;
$$;

