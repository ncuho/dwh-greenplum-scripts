CREATE FUNCTION etl.rebuild_production_day (p_from date, p_to date, p_batch_id bigint)
    RETURNS bigint
    LANGUAGE plpgsql
    VOLATILE
    AS $$
DECLARE
    n bigint;
BEGIN
    IF p_batch_id IS NULL
        OR p_batch_id <> 1
        OR p_from IS NULL
        OR p_to IS NULL
        OR p_from >= p_to
        OR p_from <> date_trunc('month', p_from)::date
        OR p_to <> date_trunc('month', p_to)::date THEN
        RAISE EXCEPTION 'ALIGNED_MONTH_RANGE_REQUIRED';
    END IF;
    IF p_from < date '2025-01-01' OR p_to > date '2026-01-01' THEN
        RAISE EXCEPTION 'OUTSIDE_SYNTHETIC_PERIOD';
    END IF;
    IF EXISTS (
        SELECT
            1
        FROM
            dds.dim_well_scd2 a
            JOIN dds.dim_well_scd2 b ON a.well_id = b.well_id
                AND a.well_sk < b.well_sk
                AND a.valid_from < b.valid_to
                AND b.valid_from < a.valid_to) THEN
        RAISE EXCEPTION 'SCD_OVERLAP';
    END IF;
    IF EXISTS (
        SELECT
            w.id,
            c.business_date
        FROM
            ods.og_tbl_well w
        CROSS JOIN ref.calendar c
        LEFT JOIN dds.dim_well_scd2 s ON s.well_id = w.id
            AND c.business_date >= s.valid_from
            AND c.business_date < s.valid_to
    WHERE
        c.business_date >= p_from
        AND c.business_date < p_to
    GROUP BY
        w.id,
        c.business_date
    HAVING
        count(s.well_sk) <> 1) THEN
        RAISE EXCEPTION 'SCD_GAP';
    END IF;
    IF EXISTS (
        SELECT
            1
        FROM
            dds.fact_downtime_interval
        WHERE
            starts_at IS NULL
            OR ends_at IS NULL
            OR starts_at >= ends_at) THEN
        RAISE EXCEPTION 'INVALID_DOWNTIME_INTERVAL';
    END IF;
    IF EXISTS (
        SELECT
            1
        FROM
            dds.fact_downtime_interval a
            JOIN dds.fact_downtime_interval b ON a.well_id = b.well_id
                AND a.downtime_id < b.downtime_id
                AND a.starts_at < b.ends_at
                AND b.starts_at < a.ends_at) THEN
        RAISE EXCEPTION 'DOWNTIME_OVERLAP';
    END IF;
    LOCK TABLE dds.fact_production_day IN EXCLUSIVE MODE;
    CREATE TEMP TABLE production_weights ON COMMIT DROP AS
    SELECT
        p.id AS source_month_id, p.well_id, c.business_date, round(p.oil_volume::numeric, 6) AS oil_month, round(p.gas_volume::numeric, 6) AS gas_month, round(p.water_volume::numeric, 6) AS water_month, (24 - coalesce(sum(
                    CASE WHEN x.downtime_id IS NOT NULL THEN
                        extract(epoch FROM least (x.ends_at, c.business_date::timestamp + interval '1 day') - greatest (x.starts_at, c.business_date::timestamp)) / 3600
                    ELSE
                        0
                    END), 0))::numeric(8, 3) AS operating_hours
    FROM
        ods.og_tbl_production_volume p
        JOIN ref.calendar c ON date_trunc('month', p.prod_date)::date = c.month_start
    LEFT JOIN dds.fact_downtime_interval x ON x.well_id = p.well_id
        AND x.starts_at < c.business_date::timestamp + interval '1 day'
        AND x.ends_at > c.business_date::timestamp
    WHERE
    p.prod_date >= p_from
    AND p.prod_date < p_to
    GROUP BY
    p.id, p.well_id, c.business_date, p.oil_volume, p.gas_volume, p.water_volume DISTRIBUTED BY
        (well_id);
    IF EXISTS (
        SELECT
            1
        FROM
            production_weights
        GROUP BY
            well_id,
            source_month_id
        HAVING
            sum(operating_hours) <= 0) THEN
        RAISE EXCEPTION 'MONTH_WITHOUT_OPERATING_HOURS';
    END IF;
    IF EXISTS (
        SELECT
            1
        FROM
            production_weights
        WHERE
            operating_hours < 0
            OR operating_hours > 24) THEN
        RAISE EXCEPTION 'INVALID_OPERATING_HOURS';
    END IF;
    CREATE TEMP TABLE production_floors ON COMMIT DROP AS
    SELECT
        *, trunc(oil_month * operating_hours / sum(operating_hours) OVER (PARTITION BY well_id, source_month_id), 6) AS oil_floor, trunc(gas_month * operating_hours / sum(operating_hours) OVER (PARTITION BY well_id, source_month_id), 6) AS gas_floor, trunc(water_month * operating_hours / sum(operating_hours) OVER (PARTITION BY well_id, source_month_id), 6) AS water_floor, max(
            CASE WHEN operating_hours > 0 THEN
                business_date
            END) OVER (PARTITION BY well_id, source_month_id) AS residual_day
    FROM
        production_weights DISTRIBUTED BY
            (well_id);
    IF EXISTS (
        SELECT
            1
        FROM
            production_weights
        GROUP BY
            well_id,
            source_month_id
        HAVING
            sum(operating_hours) <= 0) THEN
        RAISE EXCEPTION 'MONTH_WITHOUT_OPERATING_HOURS';
    END IF;
    DELETE FROM dds.fact_production_day
    WHERE business_date >= p_from
        AND business_date < p_to;
    INSERT INTO dds.fact_production_day
    SELECT
        f.well_id,
        f.business_date,
        s.well_sk,
        f.source_month_id,
        f.oil_floor + CASE WHEN business_date = residual_day THEN
            oil_month - sum(oil_floor) OVER (PARTITION BY f.well_id, source_month_id)
        ELSE
            0
        END,
        f.gas_floor + CASE WHEN business_date = residual_day THEN
            gas_month - sum(gas_floor) OVER (PARTITION BY f.well_id, source_month_id)
        ELSE
            0
        END,
        f.water_floor + CASE WHEN business_date = residual_day THEN
            water_month - sum(water_floor) OVER (PARTITION BY f.well_id, source_month_id)
        ELSE
            0
        END,
        operating_hours,
        'legacy_numeric_proxy_v1',
        1
    FROM
        production_floors f
        JOIN dds.dim_well_scd2 s ON s.well_id = f.well_id
            AND f.business_date >= s.valid_from
            AND f.business_date < s.valid_to;
    GET DIAGNOSTICS n = ROW_COUNT;
    DROP TABLE production_floors;
    DROP TABLE production_weights;
    RETURN n;
END;
$$;

