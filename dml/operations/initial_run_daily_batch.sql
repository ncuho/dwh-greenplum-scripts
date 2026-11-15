SELECT
    etl.run_daily_batch (1, date '2025-01-01', date '2026-01-01', nextval('ctl.run_id_seq'));

