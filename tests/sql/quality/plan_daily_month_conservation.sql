SELECT
    json_build_object('check', 'plan_daily_month_conservation', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    well_id, date_trunc('month', business_date)::date m, sum(plan_oil_legacy) x FROM dm.well_day_balance GROUP BY 1, 2) d
            JOIN dds.fact_production_plan_month p ON p.well_id = d.well_id
                AND p.month_start = d.m
                AND p.scenario = 'base'
            WHERE
                d.x <> p.oil_plan_legacy));

