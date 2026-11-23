-- Контекст миграции: AS IS / TO BE.
-- Назначение: Схема приёма неизменённых событий и технического контроля загрузки.
-- AS IS: Создаёт схемы/sequence и физические объекты исходного GP.
-- TO BE: Iceberg REST catalog хранит namespaces/table metadata; compute отделён от хранения.
-- Отличие: GP sequence, distribution и индексы не становятся механизмами Iceberg.
-- Конец контекста миграции.
CREATE SCHEMA oil_stg;
