CREATE TABLE ref.energy_tariff (
    "tariff_id" integer NOT NULL,
    "valid_from" date,
    "valid_to" date,
    "rub_per_kwh" ref.tariff_rate,
    "currency_code" text,
    PRIMARY KEY ("tariff_id")
)
DISTRIBUTED REPLICATED;

COMMENT ON TABLE ref.energy_tariff IS 'One tariff and half-open effective interval; synthetic demonstration, not production certification';
