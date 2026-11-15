SELECT
    locality_id,
    month_start,
    product_id,
    opening_m3,
    received_synthetic_m3,
    dispatched_m3,
    closing_m3,
    revenue_rub,
    run_id
FROM dm.shipment_balance_month
ORDER BY locality_id, month_start, product_id;
