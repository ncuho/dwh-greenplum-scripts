SELECT
    row_to_json(r)
FROM
    etl.verify_negative_gates () r;

