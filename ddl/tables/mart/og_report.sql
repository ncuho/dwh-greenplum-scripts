CREATE TABLE mart.og_report (
    "id" bigint,
    "clientou_id" bigint,
    "year" bigint,
    "month" bigint,
    "cnt" bigint,
    "avg_resolution_min" double precision,
    "pct_usedkb" double precision,
    "pct_first_time" double precision,
    "avg_answer" double precision,
    "total_time_hours" double precision
)
DISTRIBUTED BY (id);

COMMENT ON TABLE mart.og_report IS 'Сводный отчёт по КПЭ (ОЕ × месяц); synthetic demonstration, not production certification';
