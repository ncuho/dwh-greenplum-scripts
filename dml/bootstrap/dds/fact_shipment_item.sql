INSERT INTO dds.fact_shipment_item
SELECT
    locality_id,
    shipment_id,
    1,
    1,
    1000 + (locality_id % 10) * 100,
    850,
    round((1000 + (locality_id % 10) * 100) * 35000, 2),
    1
FROM
    dds.fact_shipment;

