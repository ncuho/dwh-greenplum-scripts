CREATE TABLE dds.fact_shipment (
    "shipment_id" bigint NOT NULL,
    "locality_id" bigint NOT NULL,
    "dispatched_at" timestamp,
    "buyer_contract_code" text,
    "transport_mode" text,
    "document_status" text,
    "batch_id" bigint,
    PRIMARY KEY ("locality_id","shipment_id")
)
DISTRIBUTED BY (locality_id);

COMMENT ON TABLE dds.fact_shipment IS 'One field dispatch document in independent physical scenario; synthetic demonstration, not production certification';
