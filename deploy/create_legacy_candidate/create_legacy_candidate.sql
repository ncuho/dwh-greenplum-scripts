-- Назначение: Отдельно создаёт архивный экспорт после заполнения дневной витрины; в основную установку и активные цепочки не входит.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
-- Optional: execute after production mart contains the baseline.
\set ON_ERROR_STOP on
\ir ../../ddl/tables/oil_mart/legacy_field_month_export_2024/legacy_field_month_export_2024.sql
