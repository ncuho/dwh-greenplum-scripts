# oil_gp_release

Управляемое применение партий и пересчёт двух цепочек Greenplum. Код: [oil_gp_release.py](oil_gp_release.py).

Airflow → `oil_gp_release` → Trigger DAG with config → `{}`. DAG автоматически выбирает не более 100 READY-партий. Он получает Kafka lease, запрещает producer write, ставит GP sink на паузу и удерживает advisory lock; checkpoints должны совпасть с broker cut.

В одной GP connection выполняются `apply_batch` для выбранных партий, затем `refresh_production` и `refresh_downtime`. В конце fence освобождается. При большем числе партий требуется согласованное объединение через `coalesce_ready_batches`, а не слепой retry.

Успех доставки Kafka не заменяет успешное применение DDS. При ошибке сохраняется диагностика; после crash состояние lease проверяет оператор. Прямые DML service runner не выданы. Расписание выключено; запуск выполняется явно.
