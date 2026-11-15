CREATE MATERIALIZED VIEW dm.mv_field_month_energy AS
SELECT
    locality_id,
    month_start,
    sum(energy_cost_rub) AS energy_cost_rub
FROM
    dm.field_month_performance
GROUP BY
    locality_id,
    month_start DISTRIBUTED BY
        (locality_id);

