CREATE INDEX ix_equipment_type_bitmap ON dds.dim_equipment USING bitmap (equipment_type);

