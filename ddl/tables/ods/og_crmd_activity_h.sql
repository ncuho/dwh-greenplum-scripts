CREATE TABLE ods.og_crmd_activity_h (
    "id" bigint,
    "category" text,
    "priority" text,
    "partner" text,
    "completion" boolean
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_crmd_activity_h IS 'CRM-активности; synthetic demonstration, not production certification';
