CREATE TABLE mart.bo_werks_text (
    "zkz_werks" text,
    "werks_name" text,
    "werks_text" text
)
DISTRIBUTED BY (zkz_werks);

COMMENT ON TABLE mart.bo_werks_text IS 'Заводы (werks); synthetic demonstration, not production certification';
