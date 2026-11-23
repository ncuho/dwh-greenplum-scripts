-- Контекст миграции: AS IS / TO BE.
-- Назначение: Схема интеграции и истории бизнес-сущностей с hubs, links и satellites.
-- AS IS: Создаёт схемы/sequence и физические объекты исходного GP.
-- TO BE: Iceberg REST catalog хранит namespaces/table metadata; compute отделён от хранения.
-- Отличие: GP sequence, distribution и индексы не становятся механизмами Iceberg.
-- Конец контекста миграции.
CREATE SCHEMA oil_dds;
