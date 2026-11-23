-- Ранжирует версии добычи и выбирает последнюю неудалённую запись каждого ключа.
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
