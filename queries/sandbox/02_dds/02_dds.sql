-- Назначение: Read-only разбор истории и выбора актуальной версии добычи.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
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
