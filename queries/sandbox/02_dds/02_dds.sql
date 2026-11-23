-- Контекст миграции: AS IS / TO BE.
-- Назначение: Read-only разбор истории и выбора актуальной версии добычи.
-- AS IS: Read-only исследование соответствующего слоя GP.
-- TO BE: Аналогичный просмотр выполняется через Cedrus или Spark по namespace выпуска.
-- Отличие: Запрос объясняет данные; сам по себе не выполняет перенос и не доказывает полную сверку.
-- Конец контекста миграции.
-- Greenplum: compare event versions with the latest business state; read-only.
WITH versions AS (
    SELECT
        production_hk,
        production_date,
        entity_version,
        op,
        oil_tonnes,
        row_number() OVER (
            PARTITION BY production_hk
            ORDER BY entity_version DESC, event_id DESC
        ) AS version_rank
    FROM oil_dds.sat_daily_production
)
SELECT production_hk, production_date, entity_version, oil_tonnes
FROM versions
WHERE version_rank = 1 AND op = 'U'
ORDER BY production_date, production_hk
LIMIT 25;
