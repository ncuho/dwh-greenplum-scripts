CREATE TABLE ods.og_crmd_orderadm_h (
    "object_id" text,
    "process_type" text,
    "posting_date" date,
    "description" text,
    "partner" text
)
DISTRIBUTED BY (object_id);

COMMENT ON TABLE ods.og_crmd_orderadm_h IS 'Заказы (шапка); synthetic demonstration, not production certification';
