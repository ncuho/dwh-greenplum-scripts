INSERT INTO ref.calendar
SELECT
    d::date,
    extract(year FROM d)::int,
    extract(month FROM d)::int,
    date_trunc('month', d)::date,
    extract(day FROM d)::int,
    extract(day FROM date_trunc('month', d) + interval '1 month' - interval '1 day')::int,
    extract(isodow FROM d) IN (6, 7)
FROM
    generate_series(timestamp '2025-01-01', timestamp '2025-12-31', interval '1 day') AS d;

