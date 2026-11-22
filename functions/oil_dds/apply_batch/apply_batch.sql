CREATE OR REPLACE FUNCTION oil_dds.apply_batch (p_batch_id bigint)
    RETURNS void
    AS $$
DECLARE
    bad bigint;
BEGIN
    IF NOT pg_catalog.pg_try_advisory_xact_lock(860223191::bigint) THEN
        RAISE EXCEPTION 'oil source is fenced';
    END IF;
    IF (
        SELECT
            count(*)
        FROM
            oil_stg.batch_control
        WHERE
            batch_id = p_batch_id
            AND status = 'APPLIED') = 1 THEN
        RETURN;
    END IF;
    IF (
        SELECT
            count(*)
        FROM
            oil_stg.batch_control
        WHERE
            batch_id = p_batch_id
            AND status = 'READY') <> 1 THEN
        RAISE EXCEPTION 'batch % not READY', p_batch_id;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_stg.v_event_parsed e
    WHERE
        batch_id = p_batch_id
        AND (e.schema_version IS DISTINCT FROM 1
            OR e.event_id IS NULL
            OR e.event_id = ''
            OR e.event_type IS NULL
            OR e.event_type NOT IN ('field', 'well', 'production_day', 'downtime')
            OR e.entity_id IS NULL
            OR e.entity_id !~ '^[A-Za-z0-9_-]+$'
            OR e.entity_version IS NULL
            OR e.entity_version < 1
            OR e.op IS NULL
            OR e.op NOT IN ('U', 'D')
            OR e.event_time IS NULL
            OR e.payload IS NULL
            OR e.payload = 'null'
            OR (e.payload::json ->> (
                    CASE e.event_type
                    WHEN 'production_day' THEN
                        'production_id'
                    ELSE
                        e.event_type || '_id'
                    END)) IS DISTINCT FROM e.entity_id
            OR (e.event_type = 'field'
                AND (nullif (e.payload::json ->> 'field_name', '') IS NULL OR nullif(e.payload::json->>'region','') IS NULL))
            OR (e.event_type = 'well'
                AND ((e.payload::json ->> 'field_id') IS NULL
                    OR (e.payload::json ->> 'field_id') !~ '^[A-Za-z0-9_-]+$'
                    OR nullif (e.payload::json ->> 'well_name', '') IS NULL
                    OR (e.payload::json ->> 'valid_from') IS NULL
                    OR (e.payload::json ->> 'status') IS NULL
                    OR (e.payload::json ->> 'status')
                    NOT IN ('ACTIVE', 'INACTIVE')))
            OR (e.event_type = 'production_day'
                AND ((e.payload::json ->> 'well_id') IS NULL
                    OR (e.payload::json ->> 'well_id') !~ '^[A-Za-z0-9_-]+$'
                    OR (e.payload::json ->> 'production_date') IS NULL
                    OR (e.payload::json ->> 'oil_tonnes') IS NULL
                    OR (e.payload::json ->> 'oil_tonnes')::numeric < 0
                    OR (e.payload::json ->> 'status') IS NULL
                    OR (e.payload::json ->> 'status')
                    NOT IN ('ACTIVE', 'INACTIVE')
                    OR e.entity_id IS DISTINCT FROM ((e.payload::json ->> 'well_id') || '_' || replace(e.payload::json ->> 'production_date', '-', ''))))
            OR (e.event_type = 'downtime'
                AND ((e.payload::json ->> 'well_id') IS NULL
                    OR (e.payload::json ->> 'well_id') !~ '^[A-Za-z0-9_-]+$'
                    OR (e.payload::json ->> 'start_at') IS NULL
                    OR (e.payload::json ->> 'end_at') IS NULL
                    OR (e.payload::json ->> 'reason') IS NULL
                    OR (e.payload::json ->> 'reason')
                    NOT IN ('EQUIPMENT', 'POWER', 'PLANNED')
                    OR (e.payload::json ->> 'end_at')::timestamptz <= (e.payload::json ->> 'start_at')::timestamptz
                    OR ((e.payload::json ->> 'start_at')::timestamptz AT TIME ZONE 'UTC')::date <> (((e.payload::json ->> 'end_at')::timestamptz - interval '1 microsecond') AT TIME ZONE 'UTC')::date)));
    IF bad > 0 THEN
        RAISE EXCEPTION 'invalid events in batch %, count %', p_batch_id, bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            event_id
        FROM
            oil_stg.v_event_parsed
        WHERE
            batch_id = p_batch_id
        GROUP BY
            event_id
        HAVING
            count(DISTINCT event_json) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'conflicting event IDs %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_stg.v_event_parsed e
        JOIN oil_dds.event d USING (event_id)
    WHERE
        e.batch_id = p_batch_id
        AND e.event_json <> d.event_document;
    IF bad > 0 THEN
        RAISE EXCEPTION 'reused event IDs %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            event_type,
            entity_id,
            entity_version
        FROM (
            SELECT
                event_type,
                entity_id,
                entity_version,
                event_id
            FROM
                oil_dds.event
            UNION ALL
            SELECT
                event_type,
                entity_id,
                entity_version,
                event_id
            FROM
                oil_stg.v_event_parsed
            WHERE
                batch_id = p_batch_id) v
        GROUP BY
            event_type,
            entity_id,
            entity_version
        HAVING
            count(DISTINCT event_id) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'conflicting entity versions %', bad;
    END IF;
    INSERT INTO oil_dds.event
    SELECT
        e.event_id,
        e.event_type,
        e.entity_id,
        e.entity_version,
        e.op,
        e.event_time,
        now(),
        e.topic,
        e.batch_id,
        e.payload,
        e.event_json
    FROM (
        SELECT
            p.*,
            row_number() OVER (PARTITION BY event_id ORDER BY topic, kafka_partition, kafka_offset) rn
        FROM oil_stg.v_event_parsed p
    WHERE batch_id = p_batch_id) e
WHERE
    e.rn = 1
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.event d
            WHERE
                d.event_id = e.event_id);
    INSERT INTO oil_dds.hub_field
    SELECT
        md5('field:' || entity_id),
        entity_id,
        min(load_dts),
        min(record_source)
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'field'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.hub_field h
            WHERE
                h.field_id = e.entity_id)
    GROUP BY
        entity_id;
    INSERT INTO oil_dds.hub_well
    SELECT
        md5('well:' || entity_id),
        entity_id,
        min(load_dts),
        min(record_source)
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'well'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.hub_well h
            WHERE
                h.well_id = e.entity_id)
    GROUP BY
        entity_id;
    INSERT INTO oil_dds.hub_production_day
    SELECT
        md5('production:' || entity_id),
        entity_id,
        min(load_dts),
        min(record_source)
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'production_day'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.hub_production_day h
            WHERE
                h.production_id = e.entity_id)
    GROUP BY
        entity_id;
    INSERT INTO oil_dds.hub_downtime
    SELECT
        md5('downtime:' || entity_id),
        entity_id,
        min(load_dts),
        min(record_source)
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'downtime'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.hub_downtime h
            WHERE
                h.downtime_id = e.entity_id)
    GROUP BY
        entity_id;
    INSERT INTO oil_dds.link_well_field
    SELECT
        md5('well_field:' || entity_id || ':' || (payload::json ->> 'field_id')),
        md5('well:' || entity_id),
        md5('field:' || (payload::json ->> 'field_id')),
        min(load_dts),
        min(record_source)
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'well'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.link_well_field l
            WHERE
                l.link_hk = md5('well_field:' || entity_id || ':' || (payload::json ->> 'field_id')))
    GROUP BY
        entity_id,
        payload::json ->> 'field_id';
    INSERT INTO oil_dds.link_production_day_well
    SELECT
        md5('production_day_well:' || entity_id || ':' || (payload::json ->> 'well_id')),
        md5('production:' || entity_id),
        md5('well:' || (payload::json ->> 'well_id')),
        min(load_dts),
        min(record_source)
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'production_day'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.link_production_day_well l
            WHERE
                l.link_hk = md5('production_day_well:' || entity_id || ':' || (payload::json ->> 'well_id')))
    GROUP BY
        entity_id,
        payload::json ->> 'well_id';
    INSERT INTO oil_dds.link_downtime_well
    SELECT
        md5('downtime_well:' || entity_id || ':' || (payload::json ->> 'well_id')),
        md5('downtime:' || entity_id),
        md5('well:' || (payload::json ->> 'well_id')),
        min(load_dts),
        min(record_source)
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'downtime'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.link_downtime_well l
            WHERE
                l.link_hk = md5('downtime_well:' || entity_id || ':' || (payload::json ->> 'well_id')))
    GROUP BY
        entity_id,
        payload::json ->> 'well_id';
    INSERT INTO oil_dds.sat_field
    SELECT
        md5('field:' || entity_id),
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        md5(op || ':' || payload),
        payload::json ->> 'field_name',
        payload::json ->> 'region'
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'field'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.sat_field s
            WHERE
                s.event_id = e.event_id);
    INSERT INTO oil_dds.sat_well
    SELECT
        md5('well:' || entity_id),
        md5('well_field:' || entity_id || ':' || (payload::json ->> 'field_id')),
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        md5(op || ':' || payload),
        payload::json ->> 'well_name',
        (payload::json ->> 'valid_from')::date,
        payload::json ->> 'status'
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'well'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.sat_well s
            WHERE
                s.event_id = e.event_id);
    INSERT INTO oil_dds.sat_daily_production
    SELECT
        md5('production:' || entity_id),
        md5('production_day_well:' || entity_id || ':' || (payload::json ->> 'well_id')),
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        md5(op || ':' || payload),
        (payload::json ->> 'production_date')::date,
        (payload::json ->> 'oil_tonnes')::numeric(18, 3),
        payload::json ->> 'status'
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'production_day'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.sat_daily_production s
            WHERE
                s.event_id = e.event_id);
    INSERT INTO oil_dds.sat_downtime
    SELECT
        md5('downtime:' || entity_id),
        md5('downtime_well:' || entity_id || ':' || (payload::json ->> 'well_id')),
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        md5(op || ':' || payload),
        (payload::json ->> 'start_at')::timestamptz,
        (payload::json ->> 'end_at')::timestamptz,
        payload::json ->> 'reason'
    FROM
        oil_dds.event e
    WHERE
        batch_id = p_batch_id
        AND event_type = 'downtime'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_dds.sat_downtime s
            WHERE
                s.event_id = e.event_id);
    -- Post-insert integrity checks run in this same GP transaction and rollback the batch on failure.
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            field_hk
        FROM
            oil_dds.hub_field
        GROUP BY
            field_hk
        HAVING
            count(*) > 1
        UNION ALL
        SELECT
            field_id
        FROM
            oil_dds.hub_field
        GROUP BY
            field_id
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate hub field keys %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_dds.event e
        JOIN oil_dds.hub_field h ON h.field_hk = md5('field:' || e.entity_id)
    WHERE
        e.event_type = 'field'
        AND h.field_id <> e.entity_id;
    IF bad > 0 THEN
        RAISE EXCEPTION 'hash collision hub field %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            well_hk
        FROM
            oil_dds.hub_well
        GROUP BY
            well_hk
        HAVING
            count(*) > 1
        UNION ALL
        SELECT
            well_id
        FROM
            oil_dds.hub_well
        GROUP BY
            well_id
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate hub well keys %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_dds.event e
        JOIN oil_dds.hub_well h ON h.well_hk = md5('well:' || e.entity_id)
    WHERE
        e.event_type = 'well'
        AND h.well_id <> e.entity_id;
    IF bad > 0 THEN
        RAISE EXCEPTION 'hash collision hub well %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            production_hk
        FROM
            oil_dds.hub_production_day
        GROUP BY
            production_hk
        HAVING
            count(*) > 1
        UNION ALL
        SELECT
            production_id
        FROM
            oil_dds.hub_production_day
        GROUP BY
            production_id
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate hub production_day keys %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_dds.event e
        JOIN oil_dds.hub_production_day h ON h.production_hk = md5('production:' || e.entity_id)
    WHERE
        e.event_type = 'production_day'
        AND h.production_id <> e.entity_id;
    IF bad > 0 THEN
        RAISE EXCEPTION 'hash collision hub production_day %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            downtime_hk
        FROM
            oil_dds.hub_downtime
        GROUP BY
            downtime_hk
        HAVING
            count(*) > 1
        UNION ALL
        SELECT
            downtime_id
        FROM
            oil_dds.hub_downtime
        GROUP BY
            downtime_id
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate hub downtime keys %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_dds.event e
        JOIN oil_dds.hub_downtime h ON h.downtime_hk = md5('downtime:' || e.entity_id)
    WHERE
        e.event_type = 'downtime'
        AND h.downtime_id <> e.entity_id;
    IF bad > 0 THEN
        RAISE EXCEPTION 'hash collision hub downtime %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            link_hk
        FROM
            oil_dds.link_well_field
        GROUP BY
            link_hk
        HAVING
            count(*) > 1
        UNION ALL
        SELECT
            well_hk || ':' || field_hk
        FROM
            oil_dds.link_well_field
        GROUP BY
            well_hk,
            field_hk
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate link well_field keys %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_dds.event e
        JOIN oil_dds.link_well_field l ON l.link_hk = md5('well_field:' || e.entity_id || ':' || (e.payload::json ->> 'field_id'))
    WHERE
        e.event_type = 'well'
        AND (l.well_hk <> md5('well:' || e.entity_id)
            OR l.field_hk <> md5('field:' || (e.payload::json ->> 'field_id')));
    IF bad > 0 THEN
        RAISE EXCEPTION 'hash collision link well_field %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            link_hk
        FROM
            oil_dds.link_production_day_well
        GROUP BY
            link_hk
        HAVING
            count(*) > 1
        UNION ALL
        SELECT
            production_hk || ':' || well_hk
        FROM
            oil_dds.link_production_day_well
        GROUP BY
            production_hk,
            well_hk
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate link production_day_well keys %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_dds.event e
        JOIN oil_dds.link_production_day_well l ON l.link_hk = md5('production_day_well:' || e.entity_id || ':' || (e.payload::json ->> 'well_id'))
    WHERE
        e.event_type = 'production_day'
        AND (l.production_hk <> md5('production:' || e.entity_id)
            OR l.well_hk <> md5('well:' || (e.payload::json ->> 'well_id')));
    IF bad > 0 THEN
        RAISE EXCEPTION 'hash collision link production_day_well %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            link_hk
        FROM
            oil_dds.link_downtime_well
        GROUP BY
            link_hk
        HAVING
            count(*) > 1
        UNION ALL
        SELECT
            downtime_hk || ':' || well_hk
        FROM
            oil_dds.link_downtime_well
        GROUP BY
            downtime_hk,
            well_hk
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate link downtime_well keys %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM
        oil_dds.event e
        JOIN oil_dds.link_downtime_well l ON l.link_hk = md5('downtime_well:' || e.entity_id || ':' || (e.payload::json ->> 'well_id'))
    WHERE
        e.event_type = 'downtime'
        AND (l.downtime_hk <> md5('downtime:' || e.entity_id)
            OR l.well_hk <> md5('well:' || (e.payload::json ->> 'well_id')));
    IF bad > 0 THEN
        RAISE EXCEPTION 'hash collision link downtime_well %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            event_id
        FROM
            oil_dds.sat_field
        GROUP BY
            event_id
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate sat field event IDs %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            event_id
        FROM
            oil_dds.sat_well
        GROUP BY
            event_id
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate sat well event IDs %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            event_id
        FROM
            oil_dds.sat_daily_production
        GROUP BY
            event_id
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate sat daily_production event IDs %', bad;
    END IF;
    SELECT
        count(*)
    INTO
        bad
    FROM (
        SELECT
            event_id
        FROM
            oil_dds.sat_downtime
        GROUP BY
            event_id
        HAVING
            count(*) > 1) q;
    IF bad > 0 THEN
        RAISE EXCEPTION 'duplicate sat downtime event IDs %', bad;
    END IF;
    UPDATE
        oil_stg.batch_control
    SET
        status = 'APPLIED'
    WHERE
        batch_id = p_batch_id;
END;
$$
LANGUAGE plpgsql;
