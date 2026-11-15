SELECT
    json_build_object('check', 'key:dds.dim_contract', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "contract_id"
                FROM dds.dim_contract GROUP BY "contract_id"
            HAVING
                count(*) <> 1
            OR "contract_id" IS NULL) d));

