-- Prepared definition; returns whether both dates form a nonempty half-open interval.
CREATE FUNCTION etl.valid_half_open_interval(start_date date, end_date date)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT start_date IS NOT NULL AND end_date IS NOT NULL AND start_date < end_date;
$$;
