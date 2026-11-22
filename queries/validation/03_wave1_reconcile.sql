-- DRAFT: 12 full multiset comparisons; replace identifiers only with verified FQNs.
-- GP tables must be frozen at the approved cut; read Iceberg output at the exact manifest snapshot.
-- This template uses table heads: verify each head equals its manifest snapshot before execution.
-- Validate timestamp and DECIMAL mappings, EXCEPT ALL semantics and connector support.
-- oil_dds.hub_field: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        field_hk,
        field_id,
        load_dts,
        record_source
    FROM
        < GP_CATALOG >.oil_dds.hub_field
),
t AS (
    SELECT
        field_hk,
        field_id,
        load_dts,
        record_source
    FROM
        dlh.oil_dds.r_ < RELEASE_ID > _hub_field
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_dds.hub_well: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        well_hk,
        well_id,
        load_dts,
        record_source
    FROM
        < GP_CATALOG >.oil_dds.hub_well
),
t AS (
    SELECT
        well_hk,
        well_id,
        load_dts,
        record_source
    FROM
        dlh.oil_dds.r_ < RELEASE_ID > _hub_well
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_dds.hub_production_day: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        production_hk,
        production_id,
        load_dts,
        record_source
    FROM
        < GP_CATALOG >.oil_dds.hub_production_day
),
t AS (
    SELECT
        production_hk,
        production_id,
        load_dts,
        record_source
    FROM
        dlh.oil_dds.r_ < RELEASE_ID > _hub_production_day
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_dds.link_well_field: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        link_hk,
        well_hk,
        field_hk,
        load_dts,
        record_source
    FROM
        < GP_CATALOG >.oil_dds.link_well_field
),
t AS (
    SELECT
        link_hk,
        well_hk,
        field_hk,
        load_dts,
        record_source
    FROM
        dlh.oil_dds.r_ < RELEASE_ID > _link_well_field
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_dds.link_production_day_well: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        link_hk,
        production_hk,
        well_hk,
        load_dts,
        record_source
    FROM
        < GP_CATALOG >.oil_dds.link_production_day_well
),
t AS (
    SELECT
        link_hk,
        production_hk,
        well_hk,
        load_dts,
        record_source
    FROM
        dlh.oil_dds.r_ < RELEASE_ID > _link_production_day_well
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_dds.sat_field: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        field_hk,
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        hashdiff,
        field_name,
        region
    FROM
        < GP_CATALOG >.oil_dds.sat_field
),
t AS (
    SELECT
        field_hk,
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        hashdiff,
        field_name,
        region
    FROM
        dlh.oil_dds.r_ < RELEASE_ID > _sat_field
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_dds.sat_well: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        well_hk,
        link_hk,
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        hashdiff,
        well_name,
        valid_from,
        status
    FROM
        < GP_CATALOG >.oil_dds.sat_well
),
t AS (
    SELECT
        well_hk,
        link_hk,
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        hashdiff,
        well_name,
        valid_from,
        status
    FROM
        dlh.oil_dds.r_ < RELEASE_ID > _sat_well
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_dds.sat_daily_production: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        production_hk,
        link_hk,
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        hashdiff,
        production_date,
        oil_tonnes,
        status
    FROM
        < GP_CATALOG >.oil_dds.sat_daily_production
),
t AS (
    SELECT
        production_hk,
        link_hk,
        event_id,
        entity_version,
        op,
        event_time,
        load_dts,
        record_source,
        hashdiff,
        production_date,
        oil_tonnes,
        status
    FROM
        dlh.oil_dds.r_ < RELEASE_ID > _sat_daily_production
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_mart.dim_field: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        field_hk,
        entity_version,
        valid_from,
        valid_to,
        field_name,
        region,
        is_deleted
    FROM
        < GP_CATALOG >.oil_mart.dim_field
),
t AS (
    SELECT
        field_hk,
        entity_version,
        valid_from,
        valid_to,
        field_name,
        region,
        is_deleted
    FROM
        dlh.oil_mart.r_ < RELEASE_ID > _dim_field
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_mart.dim_well: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        well_hk,
        field_hk,
        entity_version,
        valid_from,
        valid_to,
        well_name,
        status,
        is_deleted
    FROM
        < GP_CATALOG >.oil_mart.dim_well
),
t AS (
    SELECT
        well_hk,
        field_hk,
        entity_version,
        valid_from,
        valid_to,
        well_name,
        status,
        is_deleted
    FROM
        dlh.oil_mart.r_ < RELEASE_ID > _dim_well
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_mart.fact_well_day: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        production_hk,
        well_hk,
        field_hk,
        production_date,
        well_version,
        field_version,
        status,
        oil_tonnes
    FROM
        < GP_CATALOG >.oil_mart.fact_well_day
),
t AS (
    SELECT
        production_hk,
        well_hk,
        field_hk,
        production_date,
        well_version,
        field_version,
        status,
        oil_tonnes
    FROM
        dlh.oil_mart.r_ < RELEASE_ID > _fact_well_day
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;

-- oil_mart.agg_field_day: zero rows required, with multiplicity.
WITH s AS (
    SELECT
        production_date,
        field_hk,
        field_name,
        region,
        oil_tonnes,
        producing_well_days,
        oil_per_well_day
    FROM
        < GP_CATALOG >.oil_mart.agg_field_day
),
t AS (
    SELECT
        production_date,
        field_hk,
        field_name,
        region,
        oil_tonnes,
        producing_well_days,
        oil_per_well_day
    FROM
        dlh.oil_mart.r_ < RELEASE_ID > _agg_field_day
),
minus_t AS (
    SELECT
        *
    FROM
        s
    EXCEPT ALL
    SELECT
        *
    FROM
        t
),
minus_s AS (
    SELECT
        *
    FROM
        t
    EXCEPT ALL
    SELECT
        *
    FROM
        s
)
SELECT
    'gp_only' AS mismatch,
    *
FROM
    minus_t
UNION ALL
SELECT
    'dlh_only' AS mismatch,
    *
FROM
    minus_s;
