CREATE TABLE ods.og_tbl_servicecall (
    "id" bigint,
    "request_date" timestamp without time zone,
    "registration_date" timestamp without time zone,
    "state" text,
    "priority_id" bigint,
    "service_id" bigint,
    "clientou_id" bigint,
    "clientemployee_id" bigint,
    "responsibleteam_id" bigint,
    "responsibleemployee_id" bigint,
    "resolutiontime" bigint,
    "datedecision" timestamp without time zone,
    "usedkb" bigint,
    "cnt_sol" bigint,
    "answ_avg" bigint,
    "call_infsystem" bigint,
    "impact" text,
    "urgency" text
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_servicecall IS 'Заявки (факт); synthetic demonstration, not production certification';
