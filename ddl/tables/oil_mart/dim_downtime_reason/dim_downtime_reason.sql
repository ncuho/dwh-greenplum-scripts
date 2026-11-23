-- Создаёт таблицу oil_mart.dim_downtime_reason.
CREATE TABLE oil_mart.dim_downtime_reason (
    reason text NOT NULL,
    description text NOT NULL)
DISTRIBUTED BY (reason);
