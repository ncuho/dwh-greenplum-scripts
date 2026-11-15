-- One coordinator-side call; function edits and audit commit together.
SELECT
    etl.rebuild_marts (1, nextval('ctl.run_id_seq'));

