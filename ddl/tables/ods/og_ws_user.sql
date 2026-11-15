CREATE TABLE ods.og_ws_user (
    "ws_user_id" bigint,
    "auth_user" text,
    "firstname" text,
    "lastname" text,
    "email" text,
    "phone_number" text,
    "job_title" text
)
DISTRIBUTED BY (ws_user_id);

COMMENT ON TABLE ods.og_ws_user IS 'Пользователи системы; synthetic demonstration, not production certification';
