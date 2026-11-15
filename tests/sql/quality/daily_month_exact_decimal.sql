SELECT
    json_build_object('check', 'daily_month_exact_decimal', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    source_month_id, sum(oil_legacy_quantity) o, sum(gas_legacy_quantity) g, sum(water_legacy_quantity) w FROM dds.fact_production_day GROUP BY 1) d
            JOIN ods.og_tbl_production_volume p ON p.id = d.source_month_id
            WHERE
                d.o <> round(p.oil_volume::numeric, 6)
                OR d.g <> round(p.gas_volume::numeric, 6)
                OR d.w <> round(p.water_volume::numeric, 6)));

