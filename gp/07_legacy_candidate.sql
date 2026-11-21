-- Deliberately unused historical export for the migration-scope demonstration.
-- Synthetic values derived from the baseline, shifted to 2024; not actual 2024 production.
-- No scheduled producer or BI consumer is configured for this table.
BEGIN;
CREATE TABLE oil_mart.legacy_field_month_export_2024 (
    export_month date NOT NULL,
    field_hk text NOT NULL,
    field_name text NOT NULL,
    oil_tonnes numeric(20,3) NOT NULL,
    export_status text NOT NULL,
    PRIMARY KEY (export_month, field_hk)
) DISTRIBUTED BY (field_hk);

INSERT INTO oil_mart.legacy_field_month_export_2024
SELECT (date_trunc('month',production_date)-interval '1 year')::date,
       field_hk, field_name,
       CAST(sum(oil_tonnes)*0.95 AS numeric(20,3)),
       'ARCHIVED'
FROM oil_mart.agg_field_day
GROUP BY 1,2,3;

COMMENT ON TABLE oil_mart.legacy_field_month_export_2024 IS
'Synthetic archived export used only to demonstrate an object excluded from both migration waves. No scheduled job or report is configured. Values are derived from 2025 baseline and shifted to 2024; they are not real historical production.';
GRANT SELECT ON oil_mart.legacy_field_month_export_2024 TO cedrus_gp_ro;
COMMIT;
