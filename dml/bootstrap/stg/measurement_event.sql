-- Raw envelopes are distinct landing contracts; source IDs remain traceable.
INSERT INTO stg.measurement_event
SELECT
    well_id * 100000 + (extract(doy FROM event_ts)::bigint - 1) * 24 + extract(hour FROM event_ts)::bigint,
    'telemetry:' || well_id || ':' || event_ts,
    well_id,
    event_ts,
    json_build_object('pressure_kpa', pressure_kpa, 'temperature_c', temperature_c, 'vibration_mm_s', vibration_mm_s, 'water_cut_pct', water_cut_pct),
    batch_id
FROM
    dds.fact_telemetry_hour;

