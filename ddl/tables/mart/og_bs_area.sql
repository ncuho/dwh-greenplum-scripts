CREATE TABLE mart.og_bs_area (
    "bs_area" text,
    "direction" text
)
DISTRIBUTED BY (bs_area);

COMMENT ON TABLE mart.og_bs_area IS 'Направления БС; synthetic demonstration, not production certification';
