CREATE VIEW dds.v_production_with_well AS
SELECT
    p.well_id,
    w.title,
    p.business_date,
    p.oil_legacy_quantity,
    p.gas_legacy_quantity,
    p.water_legacy_quantity,
    p.operating_hours
FROM
    dds.fact_production_day p
    JOIN ods.og_tbl_well w ON w.id = p.well_id;

