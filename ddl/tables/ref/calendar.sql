CREATE TABLE ref.calendar (
    "business_date" date NOT NULL,
    "year_no" integer,
    "month_no" integer,
    "month_start" date,
    "day_of_month" integer,
    "days_in_month" integer,
    "is_weekend" boolean,
    PRIMARY KEY ("business_date")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.calendar IS 'One business date in 2025; synthetic demonstration, not production certification';
