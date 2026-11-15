CREATE TEMP TABLE production_floors ON COMMIT DROP AS
SELECT
    *, trunc(oil_month * operating_hours / sum(operating_hours) OVER (PARTITION BY well_id, source_month_id), 6) AS oil_floor, trunc(gas_month * operating_hours / sum(operating_hours) OVER (PARTITION BY well_id, source_month_id), 6) AS gas_floor, trunc(water_month * operating_hours / sum(operating_hours) OVER (PARTITION BY well_id, source_month_id), 6) AS water_floor, max(
        CASE WHEN operating_hours > 0 THEN
            business_date
        END) OVER (PARTITION BY well_id, source_month_id) AS residual_day
FROM
    production_weights DISTRIBUTED BY
        (well_id);

