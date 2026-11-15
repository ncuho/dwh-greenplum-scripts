-- Every injected defect is reverted by a PL/pgSQL subtransaction exception.
CREATE OR REPLACE FUNCTION etl.verify_negative_gates ()
    RETURNS TABLE (
        test_name text,
        blocked boolean)
    LANGUAGE plpgsql
    VOLATILE
    AS $$
DECLARE
    k bigint;
    which integer;
    msg text;
    expected text;
BEGIN
    SELECT
        min(id) INTO k
    FROM
        ods.og_tbl_well;
    FOR which IN 1..12 LOOP
        blocked := FALSE;
        CASE which
        WHEN 1 THEN
            test_name := 'duplicate_equal_count'; expected := 'DUPLICATE_PRODUCTION_KEY';
        WHEN 2 THEN
            test_name := 'negative_energy'; expected := 'INVALID_ENERGY';
        WHEN 3 THEN
            test_name := 'orphan_well_equal_count'; expected := 'MART_JOIN_CARDINALITY';
        WHEN 4 THEN
            test_name := 'unaligned_range'; expected := 'ALIGNED_MONTH_RANGE_REQUIRED';
        WHEN 5 THEN
            test_name := 'dynamic_identifier_rejected'; expected := 'ASSET_NOT_ALLOWLISTED';
        WHEN 6 THEN
            test_name := 'invalid_json_numeric'; expected := '22P02';
        WHEN 7 THEN
            test_name := 'scd_overlap'; expected := 'SCD_OVERLAP';
        WHEN 8 THEN
            test_name := 'scd_gap'; expected := 'SCD_GAP';
        WHEN 9 THEN
            test_name := 'missing_day'; expected := 'INCOMPLETE_PRODUCTION';
        WHEN 10 THEN
            test_name := 'downtime_overlap'; expected := 'DOWNTIME_OVERLAP';
        WHEN 11 THEN
            test_name := 'null_batch'; expected := 'ALIGNED_MONTH_RANGE_REQUIRED';
        WHEN 12 THEN
            test_name := 'invalid_downtime_interval'; expected := 'INVALID_DOWNTIME_INTERVAL';
        END CASE;
        BEGIN
            CASE which
            WHEN 1 THEN
                DELETE FROM dds.fact_production_day
                WHERE well_id = k
                    AND business_date = date '2025-01-02'; INSERT INTO dds.fact_production_day
                    SELECT
                        *
                    FROM
                        dds.fact_production_day
                    WHERE
                        well_id = k
                        AND business_date = date '2025-01-01';
                        PERFORM
                            etl.rebuild_marts (1, 900001);
            WHEN 2 THEN
                UPDATE
                    dds.fact_energy_day
                SET
                    energy_kwh = -1
                WHERE
                    well_id = k
                    AND business_date = date '2025-01-01';
                    PERFORM
                        etl.rebuild_marts (1, 900002);
            WHEN 3 THEN
                INSERT INTO dds.fact_production_day
                SELECT
                    999999,
                    business_date,
                    well_sk,
                    source_month_id,
                    oil_legacy_quantity,
                    gas_legacy_quantity,
                    water_legacy_quantity,
                    operating_hours,
                    contract_code,
                    batch_id
                FROM
                    dds.fact_production_day
                WHERE
                    well_id = k
                    AND business_date = date '2025-01-01'; DELETE FROM dds.fact_production_day
                    WHERE well_id = k
                        AND business_date = date '2025-01-01';
                        PERFORM
                            etl.rebuild_marts (1, 900003);
            WHEN 4 THEN
                PERFORM
                    etl.rebuild_production_day (date '2025-01-02', date '2025-02-01', 1);
            WHEN 5 THEN
                PERFORM
                    etl.f_count_asset ('pg_catalog', 'pg_authid');
            WHEN 6 THEN
                PERFORM
                    * FROM etl.f_parse_telemetry ('{"pressure_kpa":"not-numeric"}'::json);
            WHEN 7 THEN
                INSERT INTO dds.dim_well_scd2
                SELECT
                    well_id * 10 + 9,
                    well_id,
                    locality_id,
                    date '2025-03-01',
                    date '2025-05-01',
                    'bad-overlap',
                    50,
                    FALSE
                FROM
                    dds.dim_well_scd2
                WHERE
                    well_id = k
                    AND valid_from = date '2025-01-01';
                    PERFORM
                        etl.rebuild_production_day (date '2025-01-01', date '2026-01-01', 1);
            WHEN 8 THEN
                DELETE FROM dds.dim_well_scd2
                WHERE well_id = k
                    AND valid_from = date '2025-01-01';
                    PERFORM
                        etl.rebuild_production_day (date '2025-01-01', date '2026-01-01', 1);
            WHEN 9 THEN
                DELETE FROM dds.fact_production_day
                WHERE well_id = k
                    AND business_date = date '2025-01-01';
                    PERFORM
                        etl.rebuild_marts (1, 900009);
            WHEN 10 THEN
                INSERT INTO dds.fact_downtime_interval
                SELECT
                    9999999,
                    well_id,
                    starts_at + interval '1 hour',
                    ends_at,
                    reason_id,
                    repair_order_id,
                    planned,
                    batch_id
                FROM
                    dds.fact_downtime_interval
                WHERE
                    well_id = k
                    AND downtime_id = k * 10 + 1;
                    PERFORM
                        etl.rebuild_production_day (date '2025-01-01', date '2026-01-01', 1);
            WHEN 11 THEN
                PERFORM
                    etl.rebuild_production_day (date '2025-01-01', date '2026-01-01', NULL);
            WHEN 12 THEN
                UPDATE
                    dds.fact_downtime_interval
                SET
                    ends_at = starts_at - interval '1 hour'
                WHERE
                    well_id = k
                    AND downtime_id = k * 10 + 1;
                    PERFORM
                        etl.rebuild_production_day (date '2025-01-01', date '2026-01-01', 1);
            END CASE;
            RAISE EXCEPTION 'NEGATIVE_GATE_DID_NOT_BLOCK';
        EXCEPTION
        WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS msg = MESSAGE_TEXT; blocked := msg = expected
                OR SQLSTATE = expected; IF NOT blocked THEN
                    RAISE EXCEPTION 'UNEXPECTED_NEGATIVE_RESULT: %', test_name;
                    END IF;
END;
            RETURN NEXT;
        END LOOP;
END;
$$;

