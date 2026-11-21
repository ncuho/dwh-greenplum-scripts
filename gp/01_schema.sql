-- GP6 draft: apply only in a fresh isolated namespace after owner/backup checks.
CREATE SCHEMA oil_stg;
CREATE SCHEMA oil_dds;
CREATE SCHEMA oil_mart;
CREATE TABLE oil_stg.event_log (
 topic text NOT NULL, kafka_partition integer NOT NULL, kafka_offset bigint NOT NULL,
 batch_id bigint NOT NULL, received_at timestamptz NOT NULL DEFAULT now(), event_json text NOT NULL,
 PRIMARY KEY(topic,kafka_partition,kafka_offset)
) DISTRIBUTED BY(topic,kafka_partition);
CREATE TABLE oil_stg.batch_control (
 batch_id bigint PRIMARY KEY, source_name text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
 status text NOT NULL CHECK(status IN ('OPEN','READY','COALESCED','APPLIED','FAILED')), source_manifest text, error_text text
) DISTRIBUTED BY(batch_id);
-- next_offset is exclusive: all smaller offsets were durably staged in same transaction.
CREATE TABLE oil_stg.kafka_checkpoint (
 topic text NOT NULL, kafka_partition integer NOT NULL, next_offset bigint NOT NULL,
 updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(topic,kafka_partition)
) DISTRIBUTED BY(topic,kafka_partition);
CREATE TABLE oil_stg.event_reject (topic text, kafka_partition integer, kafka_offset bigint,
 event_json text, reason text NOT NULL, rejected_at timestamptz NOT NULL DEFAULT now()) DISTRIBUTED BY(topic,kafka_partition);

-- Event ledger is in DDS; unique event ID and version are guarded by apply function.
CREATE TABLE oil_dds.event (
 event_id text PRIMARY KEY, event_type text NOT NULL, entity_id text NOT NULL, entity_version bigint NOT NULL,
 op text NOT NULL, event_time timestamptz NOT NULL, load_dts timestamptz NOT NULL, record_source text NOT NULL,
 batch_id bigint NOT NULL, payload text NOT NULL, event_document text NOT NULL
) DISTRIBUTED BY(event_id);
CREATE TABLE oil_dds.hub_field (field_hk text NOT NULL,field_id text NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL) DISTRIBUTED BY(field_hk);
CREATE TABLE oil_dds.hub_well (well_hk text NOT NULL,well_id text NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL) DISTRIBUTED BY(well_hk);
CREATE TABLE oil_dds.hub_production_day (production_hk text NOT NULL,production_id text NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL) DISTRIBUTED BY(production_hk);
CREATE TABLE oil_dds.hub_downtime (downtime_hk text NOT NULL,downtime_id text NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL) DISTRIBUTED BY(downtime_hk);
CREATE TABLE oil_dds.link_well_field (link_hk text NOT NULL,well_hk text NOT NULL,field_hk text NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL) DISTRIBUTED BY(well_hk);
CREATE TABLE oil_dds.link_production_day_well (link_hk text NOT NULL,production_hk text NOT NULL,well_hk text NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL) DISTRIBUTED BY(production_hk);
CREATE TABLE oil_dds.link_downtime_well (link_hk text NOT NULL,downtime_hk text NOT NULL,well_hk text NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL) DISTRIBUTED BY(downtime_hk);
-- One row per accepted event (not merely per changed hashdiff); hash is not cryptographic integrity proof.
CREATE TABLE oil_dds.sat_field (field_hk text NOT NULL,event_id text NOT NULL,entity_version bigint NOT NULL,op text NOT NULL,event_time timestamptz NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL,hashdiff text NOT NULL,field_name text,region text) DISTRIBUTED BY(field_hk);
CREATE TABLE oil_dds.sat_well (well_hk text NOT NULL,link_hk text NOT NULL,event_id text NOT NULL,entity_version bigint NOT NULL,op text NOT NULL,event_time timestamptz NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL,hashdiff text NOT NULL,well_name text,valid_from date,status text) DISTRIBUTED BY(well_hk);
CREATE TABLE oil_dds.sat_daily_production (production_hk text NOT NULL,link_hk text NOT NULL,event_id text NOT NULL,entity_version bigint NOT NULL,op text NOT NULL,event_time timestamptz NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL,hashdiff text NOT NULL,production_date date,oil_tonnes numeric(18,3),status text) DISTRIBUTED BY(production_hk);
CREATE TABLE oil_dds.sat_downtime (downtime_hk text NOT NULL,link_hk text NOT NULL,event_id text NOT NULL,entity_version bigint NOT NULL,op text NOT NULL,event_time timestamptz NOT NULL,load_dts timestamptz NOT NULL,record_source text NOT NULL,hashdiff text NOT NULL,start_at timestamptz,end_at timestamptz,reason text) DISTRIBUTED BY(downtime_hk);

CREATE TABLE oil_mart.dim_field (field_hk text NOT NULL,entity_version bigint NOT NULL,valid_from timestamptz NOT NULL,valid_to timestamptz,field_name text,region text,is_deleted boolean NOT NULL) DISTRIBUTED BY(field_hk);
CREATE TABLE oil_mart.dim_well (well_hk text NOT NULL,field_hk text NOT NULL,entity_version bigint NOT NULL,valid_from date NOT NULL,valid_to date,well_name text,status text,is_deleted boolean NOT NULL) DISTRIBUTED BY(well_hk);
CREATE TABLE oil_mart.dim_downtime_reason (reason text NOT NULL,description text NOT NULL) DISTRIBUTED BY(reason);
CREATE TABLE oil_mart.fact_well_day (production_hk text NOT NULL,well_hk text NOT NULL,field_hk text NOT NULL,production_date date NOT NULL,well_version bigint NOT NULL,field_version bigint NOT NULL,status text NOT NULL,oil_tonnes numeric(18,3) NOT NULL) DISTRIBUTED BY(well_hk);
CREATE TABLE oil_mart.fact_downtime_interval (downtime_hk text NOT NULL,well_hk text NOT NULL,field_hk text NOT NULL,start_at timestamptz NOT NULL,end_at timestamptz NOT NULL,reason text NOT NULL,hours numeric(16,6) NOT NULL) DISTRIBUTED BY(well_hk);
CREATE TABLE oil_mart.agg_field_day (production_date date NOT NULL,field_hk text NOT NULL,field_name text NOT NULL,region text NOT NULL,oil_tonnes numeric(22,3) NOT NULL,producing_well_days bigint NOT NULL,oil_per_well_day numeric(22,6)) DISTRIBUTED BY(field_hk);

CREATE TABLE oil_mart.agg_field_downtime_day (production_date date NOT NULL,field_hk text NOT NULL,downtime_hours numeric(20,6) NOT NULL) DISTRIBUTED BY(field_hk);
