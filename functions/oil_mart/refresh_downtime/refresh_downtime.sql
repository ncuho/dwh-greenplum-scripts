-- После production refresh выбирает актуальные интервалы, проверяет активный скважино-день и отсутствие пересечений, рассчитывает часы и дневные суммы.
CREATE OR REPLACE FUNCTION oil_mart.refresh_downtime ()
    RETURNS void
    AS $$
DECLARE
    bad bigint;
BEGIN
    -- После production refresh выбираем актуальные простои, проверяем их связь с активной добычей и суммируем часы.
    IF NOT pg_catalog.pg_try_advisory_xact_lock(860223191::bigint) THEN
        RAISE EXCEPTION 'oil source is fenced';
    END IF;
    -- Начинаем полный пересчёт внутри транзакции; при последующей ошибке DELETE и INSERT откатятся вместе.
    DELETE FROM oil_mart.fact_downtime_interval;
    DELETE FROM oil_mart.agg_field_downtime_day;
    DELETE FROM oil_mart.dim_downtime_reason;
    -- Справочник причин: задаём три согласованные категории EQUIPMENT, POWER, PLANNED.
    INSERT INTO oil_mart.dim_downtime_reason
    VALUES
        ('EQUIPMENT', 'Оборудование'),
        ('POWER', 'Энергоснабжение'),
        ('PLANNED', 'Плановый простой');
    -- Факт простоев: выбираем последнюю U-версию, соединяем с активным скважино-днём и считаем длительность в часах.
    INSERT INTO oil_mart.fact_downtime_interval
    SELECT
        d.downtime_hk,
        l.well_hk,
        p.field_hk,
        d.start_at,
        d.end_at,
        d.reason,
        (extract(epoch FROM (d.end_at - d.start_at)) / 3600)::numeric(16, 6)
    FROM (
        SELECT
            *,
            row_number() OVER (PARTITION BY downtime_hk ORDER BY entity_version DESC, event_id DESC) rn
        FROM oil_dds.sat_downtime) d
    JOIN oil_dds.link_downtime_well l ON l.link_hk = d.link_hk
    JOIN oil_mart.fact_well_day p ON p.well_hk = l.well_hk
        AND p.production_date = (d.start_at AT TIME ZONE 'UTC')::date
        AND p.status = 'ACTIVE'
WHERE
    d.rn = 1
        AND d.op = 'U';
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            d.downtime_hk
        FROM (
            SELECT
                *,
                row_number() OVER (PARTITION BY downtime_hk ORDER BY entity_version DESC, event_id DESC) rn
            FROM oil_dds.sat_downtime) d
    WHERE d.rn = 1
        AND d.op = 'U'
        AND (
        SELECT
            count(*)
        FROM oil_mart.fact_downtime_interval f
    WHERE f.downtime_hk = d.downtime_hk) <> 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'downtime has no uniquely active well/day %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_mart.fact_downtime_interval a
        JOIN oil_mart.fact_downtime_interval b ON a.well_hk = b.well_hk
            AND a.downtime_hk < b.downtime_hk
            AND a.start_at < b.end_at
            AND b.start_at < a.end_at;
    IF bad > 0 THEN
        RAISE EXCEPTION 'overlapping downtime intervals %', bad;
    END IF;
    -- Агрегат простоев: суммируем часы по производственной дате UTC и месторождению.
    INSERT INTO oil_mart.agg_field_downtime_day
    SELECT
        (start_at AT TIME ZONE 'UTC')::date,
        field_hk,
        sum(hours)::numeric(20, 6)
    FROM
        oil_mart.fact_downtime_interval
    GROUP BY
        1,
        2;
END;
$$
-- Выполняется от ограниченного владельца функции; Airflow не получает прямую запись в DDS/Marts.
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp;
