CREATE TABLE mart.dm_well_more (
    "id" bigint,
    "well_id" bigint,
    "locality_name" text,
    "with_fire" text,
    "with_explode" text,
    "injuries" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE mart.dm_well_more IS 'Витрина скважин (расширенная); synthetic demonstration, not production certification';
