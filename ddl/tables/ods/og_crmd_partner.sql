CREATE TABLE ods.og_crmd_partner (
    "id" bigint,
    "partner_fct" text,
    "partner_no" text,
    "order_id" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_crmd_partner IS 'Партнёры заказов; synthetic demonstration, not production certification';
