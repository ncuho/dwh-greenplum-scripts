SELECT
    servicecall_id,
    well_id,
    linked_date,
    association_basis,
    is_causal_evidence,
    downtime_hours,
    run_id
FROM dm.service_production_impact
ORDER BY servicecall_id, well_id;
