-- GP 6.26.2. Изолированный учебный namespace; выполняется только после
-- проверки отсутствия объектов и сохранения baseline. DDL не удаляет данные.
CREATE SCHEMA demo_stg;
CREATE SCHEMA demo_ods;
CREATE SCHEMA demo_vault;
CREATE SCHEMA demo_dm;

-- Зерно: запись конкретной партиции и позиции Kafka. Позиция отражает лишь
-- доставку в staging; самостоятельный transactional offset commit не заявлен.
CREATE TABLE demo_stg.kafka_event (
 topic text NOT NULL,
 kafka_partition integer NOT NULL,
 kafka_offset bigint NOT NULL,
 batch_id bigint NOT NULL,
 received_at timestamp with time zone NOT NULL DEFAULT now(),
 event_json text NOT NULL,
 PRIMARY KEY (topic, kafka_partition, kafka_offset)
) DISTRIBUTED BY (topic, kafka_partition);

CREATE TABLE demo_stg.batch_control (
 batch_id bigint PRIMARY KEY,
 source_name text NOT NULL,
 created_at timestamp with time zone NOT NULL DEFAULT now(),
 status text NOT NULL CHECK (status IN ('OPEN','READY','APPLIED','FAILED')),
 source_manifest text,
 error_text text
) DISTRIBUTED BY (batch_id);

-- ODS — неизменяемый журнал уникальных событий; повтор того же event_id
-- допускается только при побайтно одинаковом каноническом документе.
CREATE TABLE demo_ods.event (
 event_id text PRIMARY KEY,
 event_type text NOT NULL CHECK (event_type IN ('product','store','shipment','return')),
 entity_id text NOT NULL,
 entity_version bigint NOT NULL CHECK (entity_version > 0),
 op text NOT NULL CHECK (op IN ('U','D')),
 event_time timestamp with time zone NOT NULL,
 load_dts timestamp with time zone NOT NULL DEFAULT now(),
 record_source text NOT NULL,
 batch_id bigint NOT NULL,
 payload text NOT NULL,
 event_document text NOT NULL
) DISTRIBUTED BY (event_id);

-- Raw Vault: хабы фиксируют бизнес-ключи, линки — их связи,
-- спутники — значения и версии. MD5 здесь — технический hash key учебной
-- модели, не гарантия отсутствия коллизий и не механизм безопасности.
CREATE TABLE demo_vault.hub_product (product_hk text NOT NULL, product_id text NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL) DISTRIBUTED BY (product_hk);
CREATE TABLE demo_vault.hub_store (store_hk text NOT NULL, store_id text NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL) DISTRIBUTED BY (store_hk);
CREATE TABLE demo_vault.hub_shipment (shipment_hk text NOT NULL, shipment_id text NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL) DISTRIBUTED BY (shipment_hk);
CREATE TABLE demo_vault.hub_return (return_hk text NOT NULL, return_id text NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL) DISTRIBUTED BY (return_hk);
CREATE TABLE demo_vault.link_shipment (link_hk text NOT NULL, shipment_hk text NOT NULL, product_hk text NOT NULL, store_hk text NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL) DISTRIBUTED BY (shipment_hk);
CREATE TABLE demo_vault.link_return (link_hk text NOT NULL, return_hk text NOT NULL, shipment_hk text NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL) DISTRIBUTED BY (return_hk);

-- event_id и entity_version позволяют различать replay и логическую версию.
-- event_time — время источника; load_dts — момент поступления в хранилище.
CREATE TABLE demo_vault.sat_product (product_hk text NOT NULL, event_id text NOT NULL, entity_version bigint NOT NULL, op text NOT NULL, event_time timestamp with time zone NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL, hashdiff text NOT NULL, product_name text, category text) DISTRIBUTED BY (product_hk);
CREATE TABLE demo_vault.sat_store (store_hk text NOT NULL, event_id text NOT NULL, entity_version bigint NOT NULL, op text NOT NULL, event_time timestamp with time zone NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL, hashdiff text NOT NULL, store_name text, region text) DISTRIBUTED BY (store_hk);
CREATE TABLE demo_vault.sat_shipment (shipment_hk text NOT NULL, link_hk text NOT NULL, event_id text NOT NULL, entity_version bigint NOT NULL, op text NOT NULL, event_time timestamp with time zone NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL, hashdiff text NOT NULL, order_id text, business_date date, quantity bigint, unit_price numeric(18,2), currency text) DISTRIBUTED BY (shipment_hk);
CREATE TABLE demo_vault.sat_return (return_hk text NOT NULL, link_hk text NOT NULL, event_id text NOT NULL, entity_version bigint NOT NULL, op text NOT NULL, event_time timestamp with time zone NOT NULL, load_dts timestamp with time zone NOT NULL, record_source text NOT NULL, hashdiff text NOT NULL, business_date date, quantity bigint, unit_price numeric(18,2), currency text) DISTRIBUTED BY (return_hk);

-- Звезда Kimball: версионные измерения и отдельные факты (никакого JOIN
-- нескольких фактов между собой). Составы хранят бизнес-дату в UTC-контракте.
CREATE TABLE demo_dm.dim_product (product_hk text NOT NULL, entity_version bigint NOT NULL, valid_from timestamp with time zone NOT NULL, valid_to timestamp with time zone, product_name text, category text, is_deleted boolean NOT NULL) DISTRIBUTED BY (product_hk);
CREATE TABLE demo_dm.dim_store (store_hk text NOT NULL, entity_version bigint NOT NULL, valid_from timestamp with time zone NOT NULL, valid_to timestamp with time zone, store_name text, region text, is_deleted boolean NOT NULL) DISTRIBUTED BY (store_hk);
CREATE TABLE demo_dm.fact_shipment (shipment_hk text NOT NULL, shipment_id text NOT NULL, product_hk text NOT NULL, store_hk text NOT NULL, product_version bigint NOT NULL, store_version bigint NOT NULL, business_date date NOT NULL, quantity bigint NOT NULL, unit_price numeric(18,2) NOT NULL, currency text NOT NULL, amount numeric(20,2) NOT NULL) DISTRIBUTED BY (shipment_hk);
CREATE TABLE demo_dm.fact_return (return_hk text NOT NULL, return_id text NOT NULL, shipment_hk text NOT NULL, product_hk text NOT NULL, store_hk text NOT NULL, product_version bigint NOT NULL, store_version bigint NOT NULL, business_date date NOT NULL, quantity bigint NOT NULL, unit_price numeric(18,2) NOT NULL, currency text NOT NULL, amount numeric(20,2) NOT NULL) DISTRIBUTED BY (return_hk);
CREATE TABLE demo_dm.sales_day (business_date date NOT NULL, region text NOT NULL, category text NOT NULL, currency text NOT NULL, shipment_amount numeric(22,2) NOT NULL, return_amount numeric(22,2) NOT NULL, net_amount numeric(22,2) NOT NULL, shipped_qty bigint NOT NULL, returned_qty bigint NOT NULL) DISTRIBUTED BY (business_date, region);
