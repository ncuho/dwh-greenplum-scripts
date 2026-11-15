SELECT
    json_build_object('check', 'mart_aggregate_parity', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    w.fieldid locality_id, date_trunc('month', p.prod_date)::date month_start, sum(round(p.oil_volume::numeric, 6)) oil FROM ods.og_tbl_production_volume p
                JOIN ods.og_tbl_well w ON w.id = p.well_id GROUP BY 1, 2) s
        FULL OUTER JOIN dm.field_month_performance t USING (locality_id, month_start)
    WHERE
        s.oil IS DISTINCT FROM t.oil_actual_legacy));

