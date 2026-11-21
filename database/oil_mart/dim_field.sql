CREATE TABLE oil_mart.dim_field (
    field_hk text NOT NULL,
    entity_version bigint NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_to timestamptz,
    field_name text,
    region text,
    is_deleted boolean NOT NULL)
DISTRIBUTED BY (field_hk);
