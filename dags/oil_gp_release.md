# oil_gp_release

Source DAG: удерживает Kafka fence и GP writer lock, применяет до 100 READY-партий, запускает production/downtime refresh и освобождает fence.

Исходный код: [oil_gp_release.py](oil_gp_release.py).
