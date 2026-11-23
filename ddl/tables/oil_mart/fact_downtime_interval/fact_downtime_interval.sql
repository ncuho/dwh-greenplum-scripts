-- Назначение: Факт зерна «интервал простоя». Содержит скважину, месторождение, начало/конец, причину и длительность в часах.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_mart.fact_downtime_interval (
    downtime_hk text NOT NULL,
    well_hk text NOT NULL,
    field_hk text NOT NULL,
    start_at timestamptz NOT NULL,
    end_at timestamptz NOT NULL,
    reason text NOT NULL,
    hours numeric(16, 6) NOT NULL)
DISTRIBUTED BY (well_hk);
