-- Назначение: Объединяет ограниченный диапазон READY-партий одного источника с сохранением происхождения. Работает под общей блокировкой writer.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE OR REPLACE FUNCTION oil_stg.coalesce_ready_batches (p_first_batch bigint, p_last_batch bigint, p_new_batch bigint, p_source text, p_max_events integer)
    RETURNS bigint
    AS $$
DECLARE
    v_count bigint;
    v_batches bigint;
    v_events bigint;
    v_changed bigint;
BEGIN
    IF NOT pg_catalog.pg_try_advisory_xact_lock(860223191::bigint) THEN
        RAISE EXCEPTION 'oil source is fenced';
    END IF;
    IF p_first_batch IS NULL OR p_last_batch IS NULL OR p_new_batch IS NULL OR p_source IS NULL OR p_source = '' OR p_first_batch > p_last_batch OR p_new_batch BETWEEN p_first_batch AND p_last_batch OR p_max_events IS NULL OR p_max_events < 1 OR p_max_events > 10000 THEN
        RAISE EXCEPTION 'invalid bounds/new batch/source/max events';
    END IF;
    IF EXISTS (
        SELECT
            1
        FROM
            oil_stg.batch_control
        WHERE
            batch_id = p_new_batch) OR EXISTS (
    SELECT
        1
    FROM
        oil_stg.event_log
    WHERE
        batch_id = p_new_batch) THEN
        RAISE EXCEPTION 'new batch already exists';
    END IF;
    -- Select only committed READY batches of the specified source; non-READY and
    -- other sources in range remain untouched. No claim is made of contiguous offsets.
    SELECT
        count(*)
    INTO
        v_batches
    FROM
        oil_stg.batch_control b
    WHERE
        b.batch_id BETWEEN p_first_batch AND p_last_batch
        AND b.source_name = p_source
        AND b.status = 'READY';
    IF v_batches = 0 THEN
        RAISE EXCEPTION 'no READY batches in scope';
    END IF;
    SELECT
        count(*)
    INTO
        v_events
    FROM
        oil_stg.event_log e
        JOIN oil_stg.batch_control b ON b.batch_id = e.batch_id
    WHERE
        b.batch_id BETWEEN p_first_batch AND p_last_batch
        AND b.source_name = p_source
        AND b.status = 'READY';
    IF v_events = 0 OR v_events > p_max_events THEN
        RAISE EXCEPTION 'invalid selected event count %, max %', v_events, p_max_events;
    END IF;
    SELECT
        count(*)
    INTO
        v_count
    FROM
        oil_stg.batch_control b
    WHERE
        b.batch_id BETWEEN p_first_batch AND p_last_batch
        AND b.source_name = p_source
        AND b.status = 'READY'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                oil_stg.event_log e
            WHERE
                e.batch_id = b.batch_id);
    IF v_count > 0 THEN
        RAISE EXCEPTION 'READY batches with no events %', v_count;
    END IF;
    INSERT INTO oil_stg.batch_control (batch_id, source_name, status, source_manifest)
        VALUES (p_new_batch, p_source, 'OPEN', 'coalesced; see oil_stg.batch_coalesce_map for original batch IDs');
    INSERT INTO oil_stg.batch_coalesce_map (original_batch_id, coalesced_batch_id, source_name, original_event_count)
    SELECT
        b.batch_id,
        p_new_batch,
        b.source_name,
        count(e.kafka_offset)
    FROM
        oil_stg.batch_control b
        JOIN oil_stg.event_log e ON e.batch_id = b.batch_id
    WHERE
        b.batch_id BETWEEN p_first_batch AND p_last_batch
        AND b.source_name = p_source
        AND b.status = 'READY'
    GROUP BY
        b.batch_id,
        b.source_name;
    GET DIAGNOSTICS v_changed = ROW_COUNT;
    IF v_changed <> v_batches THEN
        RAISE EXCEPTION 'batch set changed concurrently';
    END IF;
    INSERT INTO oil_stg.batch_coalesce_event_map (topic, kafka_partition, kafka_offset, original_batch_id, coalesced_batch_id)
    SELECT
        e.topic,
        e.kafka_partition,
        e.kafka_offset,
        e.batch_id,
        p_new_batch
    FROM
        oil_stg.event_log e
        JOIN oil_stg.batch_coalesce_map m ON e.batch_id = m.original_batch_id
    WHERE
        m.coalesced_batch_id = p_new_batch;
    GET DIAGNOSTICS v_changed = ROW_COUNT;
    IF v_changed <> v_events THEN
        RAISE EXCEPTION 'event mapping mismatch';
    END IF;
    UPDATE
        oil_stg.event_log e
    SET
        batch_id = p_new_batch
    FROM
        oil_stg.batch_coalesce_map m
    WHERE
        m.coalesced_batch_id = p_new_batch
        AND e.batch_id = m.original_batch_id;
    GET DIAGNOSTICS v_changed = ROW_COUNT;
    IF v_changed <> v_events THEN
        RAISE EXCEPTION 'event set changed concurrently';
    END IF;
    UPDATE
        oil_stg.batch_control b
    SET
        status = 'COALESCED'
    FROM
        oil_stg.batch_coalesce_map m
    WHERE
        m.coalesced_batch_id = p_new_batch
        AND b.batch_id = m.original_batch_id
        AND b.status = 'READY';
    GET DIAGNOSTICS v_changed = ROW_COUNT;
    IF v_changed <> v_batches THEN
        RAISE EXCEPTION 'batch state changed concurrently';
    END IF;
    UPDATE
        oil_stg.batch_control
    SET
        status = 'READY'
    WHERE
        batch_id = p_new_batch
        AND status = 'OPEN';
    RETURN v_events;
END;
$$
LANGUAGE plpgsql;
