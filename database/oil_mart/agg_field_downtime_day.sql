CREATE TABLE oil_mart.agg_field_downtime_day (
    production_date date NOT NULL,
    field_hk text NOT NULL,
    downtime_hours numeric(20, 6) NOT NULL)
DISTRIBUTED BY (field_hk);
