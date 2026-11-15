CREATE TABLE ods.og_crmd_orderadm_i (
    "id" bigint,
    "ordered_prod" text,
    "header" text,
    "number_int" text,
    "cost" double precision
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_crmd_orderadm_i IS 'Позиции заказов; synthetic demonstration, not production certification';
