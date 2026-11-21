# Нефтегазовое DWH Greenplum

Две связанные цепочки: добыча и эффективность с учётом простоев. Генератор → Kafka/Connect → `oil_stg` → `oil_dds` (Raw Vault patterns) → `oil_mart` (Kimball) → Superset. За 2025 год загружены 15525 синтетических событий: 5 месторождений, 40 скважин, 14600 well/day и 880 интервалов простоев.

Первая цепочка уже перенесена в Lakehouse; вторая подготовлена для миграции на вебинаре. `gp/` содержит DDL и реальные source routines, `ingestion/` — события, генератор и Kafka, `ingestion/wave2/` — target ingestion и fence, `quality/` — сверки, `metadata/` — зависимости. Секреты хранятся вне Git.

Начните с [22 шагов вебинара](docs/WEBINAR-22-STEPS.md), [текущего состояния и ограничений](docs/02-фактический-статус.md), [сервисов](docs/SERVICE-INDEX.md) и [доступов](docs/ACCESS-UI-RUNBOOK.md). Это демонстрационный стенд с production-подобной логикой; HA промышленного контура не заявляется.
