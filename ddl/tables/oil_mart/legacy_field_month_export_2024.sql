BEGIN;
CREATE TABLE oil_mart.legacy_field_month_export_2024 (
    export_month date NOT NULL,
    field_hk text NOT NULL,
    field_name text NOT NULL,
    oil_tonnes numeric(20, 3) NOT NULL,
    export_status text NOT NULL,
    PRIMARY KEY (export_month, field_hk))
DISTRIBUTED BY (field_hk);
INSERT INTO oil_mart.legacy_field_month_export_2024
SELECT
    (date_trunc('month', production_date) - interval '1 year')::date,
    field_hk,
    field_name,
    CAST(sum(oil_tonnes) * 0.95 AS numeric(20, 3)),
    'ARCHIVED'
FROM
    oil_mart.agg_field_day
GROUP BY
    1,
    2,
    3;
COMMENT ON TABLE oil_mart.legacy_field_month_export_2024 IS 'Archived monthly export excluded from active reporting. Values derived from the 2025 baseline with a 0.95 factor and dates shifted back one year; not verified measurements for 2024. No scheduled consumer is configured.';
GRANT SELECT ON oil_mart.legacy_field_month_export_2024 TO cedrus_gp_ro;
COMMIT;
