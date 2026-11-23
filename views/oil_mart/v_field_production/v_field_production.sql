-- Назначение: Serving-представление первой цепочки поверх agg_field_day для отчёта добычи.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE VIEW oil_mart.v_field_production AS
SELECT
    *
FROM
    oil_mart.agg_field_day;
