UPDATE
    ctl.load_batch
SET
    state = 'ENRICHED',
    finished_at = CURRENT_TIMESTAMP
WHERE
    batch_id = 1;

