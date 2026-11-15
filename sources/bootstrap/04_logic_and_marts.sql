\set ON_ERROR_STOP on

BEGIN;

\ir ../../functions/etl/f_fiscal_period.sql

\ir ../../functions/etl/f_energy_cost.sql

\ir ../../functions/etl/f_parse_telemetry.sql

\ir ../../functions/etl/f_count_asset.sql

\ir ../../functions/etl/rebuild_marts.sql

\ir ../../ddl/views/dm/v_production_dashboard.sql

\ir ../../ddl/views/dds/v_production_with_well.sql

COMMIT;

\ir ../../dml/operations/initial_rebuild_marts.sql

\ir ../../ddl/materialized_views/dm/mv_field_month_energy.sql

\ir ../../dml/maintenance/refresh_field_month_energy.sql
