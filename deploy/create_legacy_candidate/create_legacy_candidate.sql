-- Контекст миграции: AS IS / TO BE.
-- Назначение: Отдельно создаёт архивный экспорт после заполнения дневной витрины; в основную установку и активные цепочки не входит.
-- AS IS: Разворачивает исходные GP-объекты либо отдельный legacy-кандидат.
-- TO BE: Целевой deploy создаёт только согласованные Iceberg-объекты своей волны.
-- Отличие: Этот deploy не является командой очистки DLH и не запускает целевую миграцию.
-- Конец контекста миграции.
-- Optional: execute after production mart contains the baseline.
\set ON_ERROR_STOP on
\ir ../../ddl/tables/oil_mart/legacy_field_month_export_2024/legacy_field_month_export_2024.sql
