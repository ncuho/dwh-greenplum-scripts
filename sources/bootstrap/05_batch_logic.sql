\set ON_ERROR_STOP on

BEGIN;

\ir ../../functions/etl/rebuild_production_day.sql

\ir ../../functions/etl/run_daily_batch.sql

COMMIT;

\ir ../../dml/operations/initial_run_daily_batch.sql
