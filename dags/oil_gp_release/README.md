# oil_gp_release

Управляемое применение партий и пересчёт двух цепочек Greenplum. Код: [oil_gp_release.py](oil_gp_release.py).

Airflow → `oil_gp_release` → Trigger DAG with config → `{}`. Task `apply_batches_and_refresh_marts` вызывает Python `release()`, которая получает GP connection `webinar_greenplum` и выполняет `SELECT bridge_capture.prepare_source(%s)` с параметром `oil`.

`prepare_source` короткой транзакцией блокирует исходные таблицы и checkpoint, применяет не более 100 READY-партий через `oil_dds.apply_batch`, затем при наличии таких партий вызывает `oil_mart.refresh_production` и `oil_mart.refresh_downtime`. В конце `validate_coalesce_audit` сверяет карты происхождения с реальными доставками. Любая ошибка приводит к rollback; успех фиксируется одним commit.

Kafka producer и Connect продолжают работать. GP sink может ожидать завершения короткой транзакции; на время копирования INITIAL длительная блокировка не удерживается. При большем числе READY-партий требуется отдельная согласованная операция `coalesce_ready_batches`. При включённом DAG расписание выполняется каждую минуту; ручной trigger также доступен. Развёртывание сохраняет paused state, поэтому оператор включает DAG явно. Повтор задачи автоматически не выполняется.

В Data Catalog зарегистрированы pipeline, реальная task, вызываемые функции, входы проверок, физические выходы и колоночный путь к отчёту. Target DAG выполняется отдельно и не заменяет этот исходный workflow.
