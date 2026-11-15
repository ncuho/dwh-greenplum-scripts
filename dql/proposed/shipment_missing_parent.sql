SELECT
    item.locality_id,
    item.shipment_id,
    item.line_no,
    item.product_id,
    item.quantity_m3
FROM dds.fact_shipment_item AS item
LEFT JOIN dds.fact_shipment AS shipment
    ON shipment.locality_id = item.locality_id
    AND shipment.shipment_id = item.shipment_id
WHERE shipment.shipment_id IS NULL
ORDER BY item.locality_id, item.shipment_id, item.line_no;
