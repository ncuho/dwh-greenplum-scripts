INSERT INTO dds.fact_shipment
SELECT
    l.id * 100 + c.month_no,
    l.id,
    c.business_date::timestamp + interval '19 days',
    'BUYER-SYNTHETIC-' || (l.id % 4),
    'pipeline',
    'accepted',
    1
FROM
    ods.og_tbl_locality l
    JOIN ref.calendar c ON c.day_of_month = 1;

