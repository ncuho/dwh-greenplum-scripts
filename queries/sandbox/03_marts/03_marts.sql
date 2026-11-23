-- Контекст миграции: AS IS / TO BE.
-- Назначение: Read-only разбор связи факта с действовавшей версией скважины.
-- AS IS: Read-only исследование соответствующего слоя GP.
-- TO BE: Аналогичный просмотр выполняется через Cedrus или Spark по namespace выпуска.
-- Отличие: Запрос объясняет данные; сам по себе не выполняет перенос и не доказывает полную сверку.
-- Конец контекста миграции.
-- Greenplum: trace a fact to its historical dimension version; read-only.
SELECT
    f.production_date,
    w.well_name,
    f.well_version,
    f.oil_tonnes,
    f.status
FROM oil_mart.fact_well_day f
JOIN oil_mart.dim_well w
    ON w.well_hk = f.well_hk
    AND w.entity_version = f.well_version
ORDER BY f.production_date, w.well_name
LIMIT 25;
