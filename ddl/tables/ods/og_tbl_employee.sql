CREATE TABLE ods.og_tbl_employee (
    "id" bigint,
    "first_name" text,
    "last_name" text,
    "middle_name" text,
    "fio" text,
    "login" text,
    "email" text,
    "mobile_phone" text,
    "employee_employeenumber" text,
    "post" text,
    "parent_id" bigint,
    "date_of_birth" timestamp without time zone
)
DISTRIBUTED BY (id);

COMMENT ON TABLE ods.og_tbl_employee IS 'Сотрудники; synthetic demonstration, not production certification';
