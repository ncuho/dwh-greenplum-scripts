SELECT
    json_build_object('check', 'shipment_mass_balance', 'scope', 'new_contract', 'errors', (
            SELECT
                count(*)
            FROM dm.shipment_balance_month
            WHERE
                opening_m3 + received_synthetic_m3 - dispatched_m3 <> closing_m3
                OR closing_m3 < 0));

