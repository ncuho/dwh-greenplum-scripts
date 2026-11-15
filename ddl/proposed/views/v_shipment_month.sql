-- Prepared definition: dispatched month, field and product; not deployed.
CREATE VIEW dm.v_shipment_month AS
SELECT
    date_trunc('month', shipment.dispatched_at)::date AS month_start,
    shipment.locality_id,
    item.product_id,
    count(*) AS item_count,
    sum(item.quantity_m3) AS quantity_m3,
    sum(item.amount_rub) AS amount_rub
FROM dds.fact_shipment AS shipment
JOIN dds.fact_shipment_item AS item
    ON item.locality_id = shipment.locality_id
    AND item.shipment_id = shipment.shipment_id
GROUP BY date_trunc('month', shipment.dispatched_at)::date,
         shipment.locality_id,
         item.product_id;
