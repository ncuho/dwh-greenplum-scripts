-- Разрешает Airflow-загрузчику читать ровно двадцать утверждённых source-объектов в одном нативном snapshot GP.
GRANT SELECT ON
    oil_stg.batch_coalesce_event_map, oil_stg.batch_coalesce_map,
    oil_stg.batch_control, oil_stg.event_log, oil_stg.kafka_checkpoint, oil_stg.v_event_parsed,
    oil_dds.event, oil_dds.hub_field, oil_dds.hub_production_day, oil_dds.hub_well,
    oil_dds.link_production_day_well, oil_dds.link_well_field,
    oil_dds.sat_daily_production, oil_dds.sat_field, oil_dds.sat_well,
    oil_mart.dim_field, oil_mart.dim_well, oil_mart.fact_well_day,
    oil_mart.agg_field_day, oil_mart.v_field_production
TO demo_airflow_runner;
