-- Назначение: Объект online_capture. Назначение и порядок исполнения определяются согласованным контрактом этого каталога.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
-- Online capture for Greenplum 6: Kafka and Connect remain running.
-- Only GP writers wait briefly while a transaction applies READY batches and
-- materializes the consistent source image. The subsequent network copy reads
-- those immutable tables and holds no business-table or producer fence.
CREATE SCHEMA IF NOT EXISTS bridge_capture;
REVOKE ALL ON SCHEMA bridge_capture FROM PUBLIC;

CREATE TABLE IF NOT EXISTS bridge_capture.sources (
    source_id text PRIMARY KEY,
    stage_schema text NOT NULL,
    dds_schema text NOT NULL,
    mart_schema text NOT NULL,
    topic text NOT NULL,
    reader_role text NOT NULL
) DISTRIBUTED BY (source_id);

CREATE TABLE IF NOT EXISTS bridge_capture.registry (
    capture_id text PRIMARY KEY,
    source_id text NOT NULL,
    requested_by text NOT NULL,
    captured_at timestamptz NOT NULL,
    manifest json NOT NULL
) DISTRIBUTED BY (capture_id);

-- Only an administrator registers source contracts. Callers cannot inject an
-- arbitrary relation, function, role, or SQL expression into the definer scope.
INSERT INTO bridge_capture.sources
SELECT 'oil','oil_stg','oil_dds','oil_mart','oil.events.v1','cedrus_gp_ro'
WHERE NOT EXISTS (SELECT 1 FROM bridge_capture.sources WHERE source_id='oil');

CREATE OR REPLACE FUNCTION bridge_capture.prepare_source(p_source_id text)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, pg_temp AS $$
DECLARE
    cfg bridge_capture.sources%ROWTYPE;
    item record;
    batch record;
    batch_count integer := 0;
    bad bigint;
    coordinates json;
BEGIN
    SELECT * INTO STRICT cfg FROM bridge_capture.sources WHERE source_id=p_source_id;
    -- Shared writer gate with the existing apply/refresh functions. It does not
    -- change a Kafka ACL, pause a connector, or reject a producer process.
    IF NOT pg_catalog.pg_try_advisory_xact_lock(860223191::bigint) THEN
        RAISE EXCEPTION 'source writer busy; retry capture before any target write';
    END IF;
    -- GP sink takes this same checkpoint lock for each atomic delivery. Waiting
    -- here drains its current transaction and queues the next delivery normally.
    EXECUTE format('LOCK TABLE %I.kafka_checkpoint IN EXCLUSIVE MODE',cfg.stage_schema);
    -- Lock physical relations in a stable order. This also protects against
    -- ordinary writers that do not participate in the advisory-lock contract.
    FOR item IN
        SELECT n.nspname,c.relname FROM pg_class c
        JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname IN (cfg.stage_schema,cfg.dds_schema,cfg.mart_schema)
          AND c.relkind='r' ORDER BY n.nspname,c.relname
    LOOP
        EXECUTE format('LOCK TABLE %I.%I IN SHARE MODE',item.nspname,item.relname);
    END LOOP;
    EXECUTE format('SELECT count(*) FROM %I.batch_control WHERE source_name=$1 AND status IN (''OPEN'',''FAILED'')',cfg.stage_schema)
        INTO bad USING 'kafka:'||cfg.topic;
    IF bad<>0 THEN RAISE EXCEPTION 'source contains OPEN or FAILED batches'; END IF;
    EXECUTE format('SELECT count(*) FROM %I.batch_control WHERE source_name=$1 AND status=''READY''',cfg.stage_schema)
        INTO bad USING 'kafka:'||cfg.topic;
    IF bad>100 THEN RAISE EXCEPTION 'more than 100 READY batches; bounded coalesce required'; END IF;
    -- The bounded apply happens in this same transaction. A failure rolls back
    -- both source application and every capture table created by the caller.
    FOR batch IN EXECUTE format('SELECT batch_id FROM %I.batch_control WHERE source_name=$1 AND status=''READY'' ORDER BY batch_id',cfg.stage_schema)
        USING 'kafka:'||cfg.topic
    LOOP
        EXECUTE format('SELECT %I.apply_batch($1)',cfg.dds_schema) USING batch.batch_id;
        batch_count:=batch_count+1;
    END LOOP;
    IF batch_count>0 THEN
        EXECUTE format('SELECT %I.refresh_production()',cfg.mart_schema);
        EXECUTE format('SELECT %I.refresh_downtime()',cfg.mart_schema);
    END IF;
    EXECUTE format('SELECT count(*) FROM %I.event_reject',cfg.stage_schema) INTO bad;
    IF bad<>0 THEN RAISE EXCEPTION 'source contains rejected events'; END IF;
    EXECUTE format('SELECT count(*) FROM %I.event_log s LEFT JOIN %I.event d ON d.event_id=(s.event_json::json->>''event_id'') WHERE s.topic=$1 AND (d.event_id IS NULL OR d.event_document<>s.event_json)',cfg.stage_schema,cfg.dds_schema)
        INTO bad USING cfg.topic;
    IF bad<>0 THEN RAISE EXCEPTION 'source Stage/ledger mismatch'; END IF;
    EXECUTE format('SELECT count(*) FROM %I.batch_coalesce_map m LEFT JOIN %I.batch_control b ON b.batch_id=m.coalesced_batch_id WHERE b.batch_id IS NULL OR b.status<>''APPLIED''',cfg.stage_schema,cfg.stage_schema) INTO bad;
    IF bad<>0 THEN RAISE EXCEPTION 'unapplied coalesced batch'; END IF;
    EXECUTE format('SELECT json_agg(x ORDER BY "partition") FROM (SELECT kafka_partition AS "partition",next_offset AS "end" FROM %I.kafka_checkpoint WHERE topic=$1) x',cfg.stage_schema)
        INTO coordinates USING cfg.topic;
    IF coordinates IS NULL THEN RAISE EXCEPTION 'source checkpoints absent'; END IF;
    RETURN json_build_object('source_id',p_source_id,'topic',cfg.topic,
        'partitions',coordinates,'applied_batches',batch_count,
        'source_checks','PASS','producer_paused',false,'connector_paused',false);
END $$;

CREATE OR REPLACE FUNCTION bridge_capture.capture(
    p_capture_id text,p_source_id text,p_objects json
) RETURNS json LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, pg_temp AS $$
DECLARE
    cfg bridge_capture.sources%ROWTYPE;
    boundary json;
    item json;
    col json;
    source_schema text;
    source_table text;
    symbol text;
    destination text;
    fields text;
    column_name text;
    relation_oid oid;
    row_count bigint;
    tables json := '{}'::json;
    manifest json;
BEGIN
    IF p_capture_id IS NULL OR p_objects IS NULL
       OR p_capture_id !~ '^pbc_[a-f0-9]{20}_[a-f0-9]{8}$'
       OR json_typeof(p_objects)<>'array'
       OR json_array_length(p_objects) NOT BETWEEN 1 AND 100 THEN
        RAISE EXCEPTION 'invalid source capture request';
    END IF;
    IF EXISTS(SELECT 1 FROM bridge_capture.registry WHERE capture_id=p_capture_id) THEN
        RAISE EXCEPTION 'capture already exists; inspect instead of replay';
    END IF;
    SELECT * INTO STRICT cfg FROM bridge_capture.sources WHERE source_id=p_source_id;
    boundary:=bridge_capture.prepare_source(p_source_id);
    FOR item IN SELECT value FROM json_array_elements(p_objects)
    LOOP
        source_schema:=item->>'source_schema';source_table:=item->>'source_table';symbol:=item->>'symbol';
        IF source_schema IS NULL OR source_table IS NULL OR symbol IS NULL
           OR (item->'columns') IS NULL
           OR source_schema NOT IN (cfg.stage_schema,cfg.dds_schema,cfg.mart_schema)
           OR source_table !~ '^[a-z][a-z0-9_]{0,62}$'
           OR symbol !~ '^[a-z][a-z0-9_]{0,62}$'
           OR json_typeof(item->'columns')<>'array'
           OR json_array_length(item->'columns') NOT BETWEEN 1 AND 200 THEN
            RAISE EXCEPTION 'object outside registered source contract';
        END IF;
        fields:='';
        FOR col IN SELECT value FROM json_array_elements(item->'columns')
        LOOP
            column_name:=col#>>'{}';
            IF column_name IS NULL OR column_name !~ '^[a-z][a-z0-9_]{0,62}$'
               OR NOT has_column_privilege(cfg.reader_role,format('%I.%I',source_schema,source_table),column_name,'SELECT') THEN
                RAISE EXCEPTION 'source column not readable under registered reader';
            END IF;
            fields:=fields||CASE WHEN fields='' THEN '' ELSE ', ' END||format('%I',column_name);
        END LOOP;
        destination:=p_capture_id||'_'||substr(md5(symbol),1,12);
        -- CTAS preserves the actual source types and values, including audit
        -- timestamps and lexical JSON. No business constraints are fabricated.
        EXECUTE format('CREATE TABLE bridge_capture.%I AS SELECT %s FROM %I.%I DISTRIBUTED RANDOMLY',destination,fields,source_schema,source_table);
        GET DIAGNOSTICS row_count=ROW_COUNT;
        EXECUTE format('REVOKE ALL ON TABLE bridge_capture.%I FROM PUBLIC',destination);
        EXECUTE format('GRANT SELECT ON TABLE bridge_capture.%I TO %I',destination,cfg.reader_role);
        SELECT c.oid INTO STRICT relation_oid FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='bridge_capture' AND c.relname=destination;
        -- Use JSON aggregation rather than later PostgreSQL jsonb operators.
        SELECT json_object_agg(k,v) INTO tables FROM (
            SELECT key AS k,value AS v FROM json_each(tables)
            UNION ALL SELECT symbol,json_build_object(
            'schema','bridge_capture','table',destination,'oid',relation_oid,
            'source_schema',source_schema,'source_table',source_table,
            'columns',item->'columns','rows',row_count)
        ) entries;
    END LOOP;
    SELECT json_object_agg(k,v) INTO manifest FROM (
        SELECT key AS k,value AS v FROM json_each(boundary)
        UNION ALL SELECT 'capture_id',to_json(p_capture_id)
        UNION ALL SELECT 'captured_at',to_json(clock_timestamp())
        UNION ALL SELECT 'tables',tables
    ) entries;
    INSERT INTO bridge_capture.registry VALUES(p_capture_id,p_source_id,session_user,clock_timestamp(),manifest);
    RETURN manifest;
END $$;

CREATE OR REPLACE FUNCTION bridge_capture.cleanup(p_capture_id text)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, pg_temp AS $$
DECLARE
    saved bridge_capture.registry%ROWTYPE;
    item record;
    actual oid;
    removed integer:=0;
BEGIN
    IF p_capture_id !~ '^pbc_[a-f0-9]{20}_[a-f0-9]{8}$' THEN RAISE EXCEPTION 'invalid capture ID'; END IF;
    SELECT * INTO saved FROM bridge_capture.registry WHERE capture_id=p_capture_id FOR UPDATE;
    IF NOT FOUND THEN RETURN 0; END IF;
    IF saved.requested_by<>session_user AND session_user<>'gpadmin' THEN RAISE EXCEPTION 'foreign capture owner'; END IF;
    FOR item IN SELECT value FROM json_each(saved.manifest->'tables')
    LOOP
        IF item.value->>'schema'<>'bridge_capture' OR position(p_capture_id||'_' IN item.value->>'table')<>1 THEN
            RAISE EXCEPTION 'invalid stored capture identity';
        END IF;
        SELECT c.oid INTO actual FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname='bridge_capture' AND c.relname=item.value->>'table';
        IF actual IS DISTINCT FROM (item.value->>'oid')::oid THEN RAISE EXCEPTION 'capture relation identity changed'; END IF;
        EXECUTE format('DROP TABLE bridge_capture.%I',item.value->>'table');
        removed:=removed+1;
    END LOOP;
    DELETE FROM bridge_capture.registry WHERE capture_id=p_capture_id;
    RETURN removed;
END $$;

REVOKE ALL ON ALL TABLES IN SCHEMA bridge_capture FROM PUBLIC;
REVOKE ALL ON FUNCTION bridge_capture.prepare_source(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION bridge_capture.capture(text,text,json) FROM PUBLIC;
REVOKE ALL ON FUNCTION bridge_capture.cleanup(text) FROM PUBLIC;
GRANT USAGE ON SCHEMA bridge_capture TO demo_airflow_runner,cedrus_gp_ro;
GRANT EXECUTE ON FUNCTION bridge_capture.prepare_source(text),bridge_capture.capture(text,text,json),bridge_capture.cleanup(text) TO demo_airflow_runner;
GRANT SELECT ON bridge_capture.registry TO demo_airflow_runner,cedrus_gp_ro;

GRANT SELECT ON bridge_capture.sources TO cedrus_gp_ro;
