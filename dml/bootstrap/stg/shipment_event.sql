INSERT INTO stg.shipment_event
SELECT
    shipment_id,
    'shipment:' || shipment_id,
    locality_id,
    dispatched_at,
    json_build_object('status', document_status, 'transport', transport_mode),
    batch_id
FROM
    dds.fact_shipment;

