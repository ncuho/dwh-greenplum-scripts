SELECT
    json_build_object('check', 'raw_json_parse', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM stg.measurement_event
            WHERE (payload ->> 'pressure_kpa') IS NULL
            OR (payload ->> 'water_cut_pct') IS NULL));

