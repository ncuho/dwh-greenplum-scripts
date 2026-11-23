-- Назначение: Read-only SQL-проверки качества, полноты и согласованности результатов двух контуров.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
-- Read-only GP checks; zero violations is necessary, not proof of complete coverage.
SELECT
    'duplicate_well_day' check_name,
    count(*) violations
FROM (
    SELECT
        well_hk,
        production_date
    FROM
        oil_mart.fact_well_day
    GROUP BY
        1,
        2
    HAVING
        count(*) > 1) q
UNION ALL
SELECT
    'duplicate_event_version',
    count(*)
FROM (
    SELECT
        event_type,
        entity_id,
        entity_version
    FROM
        oil_dds.event
    GROUP BY
        1,
        2,
        3
    HAVING
        count(*) > 1) q
UNION ALL
SELECT
    'field_hash_collision',
    count(*)
FROM (
    SELECT
        field_hk
    FROM
        oil_dds.hub_field
    GROUP BY
        field_hk
    HAVING
        count(DISTINCT field_id) > 1) q
UNION ALL
SELECT
    'well_hash_collision',
    count(*)
FROM (
    SELECT
        well_hk
    FROM
        oil_dds.hub_well
    GROUP BY
        well_hk
    HAVING
        count(DISTINCT well_id) > 1) q
UNION ALL
SELECT
    'duplicate_well_dimension_version',
    count(*)
FROM (
    SELECT
        well_hk,
        entity_version
    FROM
        oil_mart.dim_well
    GROUP BY
        1,
        2
    HAVING
        count(*) > 1) q
UNION ALL
SELECT
    'downtime_above_day',
    count(*)
FROM (
    SELECT
        well_hk,
        (start_at AT TIME ZONE 'UTC')::date d,
        sum(hours) h
    FROM
        oil_mart.fact_downtime_interval
    GROUP BY
        1,
        2
    HAVING
        sum(hours) > 24) q
UNION ALL
SELECT
    'inactive_oil',
    count(*)
FROM
    oil_mart.fact_well_day
WHERE
    status = 'INACTIVE'
    AND oil_tonnes <> 0;
