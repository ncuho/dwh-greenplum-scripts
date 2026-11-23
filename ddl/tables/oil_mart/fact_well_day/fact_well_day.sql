-- Назначение: Факт зерна «скважина × производственная дата». Содержит тонны, статус и версии измерений well/field, действовавшие на дату.
-- Исполняйте в указанном SQL-движке; одноимённые функции и типы GP и Spark могут иметь разную семантику.
CREATE TABLE oil_mart.fact_well_day (
    production_hk text NOT NULL,
    well_hk text NOT NULL,
    field_hk text NOT NULL,
    production_date date NOT NULL,
    well_version bigint NOT NULL,
    field_version bigint NOT NULL,
    status text NOT NULL,
    oil_tonnes numeric(18, 3) NOT NULL)
DISTRIBUTED BY (well_hk);
