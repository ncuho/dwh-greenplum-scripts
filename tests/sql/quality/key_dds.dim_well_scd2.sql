SELECT
    json_build_object('check', 'key:dds.dim_well_scd2', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM (
                SELECT
                    "well_id", "well_sk"
                FROM dds.dim_well_scd2 GROUP BY "well_id", "well_sk"
            HAVING
                count(*) <> 1
            OR "well_id" IS NULL
            OR "well_sk" IS NULL) d));

