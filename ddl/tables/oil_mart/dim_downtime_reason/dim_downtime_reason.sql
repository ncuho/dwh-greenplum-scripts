-- Назначение: Справочник причин: EQUIPMENT, POWER, PLANNED. Нормализует группировку простоев.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_mart.dim_downtime_reason (
    reason text NOT NULL,
    description text NOT NULL)
DISTRIBUTED BY (reason);
