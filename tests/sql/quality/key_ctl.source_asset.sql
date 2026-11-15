SELECT
    json_build_object('check', 'key:ctl.source_asset', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "asset_name"
                FROM ctl.source_asset GROUP BY "asset_name"
            HAVING
                count(*) <> 1
            OR "asset_name" IS NULL) d));

