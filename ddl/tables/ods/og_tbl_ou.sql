CREATE TABLE ods.og_tbl_ou (
    "id" bigint,
    "title" text,
    "titleshort" text,
    "ou_code" text,
    "ou_customer" boolean,
    "parent_id" bigint
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_ou IS 'Организационные единицы (заказчики); synthetic demonstration, not production certification';
