SELECT
    json_build_object('check', 'daily_source_double_tolerance', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    source_month_id, sum(oil_legacy_quantity) o, sum(gas_legacy_quantity) g, sum(water_legacy_quantity) w FROM dds.fact_production_day GROUP BY 1) d
            JOIN ods.og_tbl_production_volume p ON p.id = d.source_month_id
            WHERE
                abs(d.o::double precision - p.oil_volume) > 0.000001 + 1e-12 * abs(p.oil_volume)
                OR abs(d.g::double precision - p.gas_volume) > 0.000001 + 1e-12 * abs(p.gas_volume)
                OR abs(d.w::double precision - p.water_volume) > 0.000001 + 1e-12 * abs(p.water_volume)));

