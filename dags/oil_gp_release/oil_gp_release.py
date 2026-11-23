# Управляемое применение партий и пересчёт двух цепочек Greenplum. Код: oil_gp_release.py.
"""Apply complete Kafka batches and refresh both GP reports online.

The database service serializes participating writers only during this source
transaction. Kafka producers and Kafka Connect remain running throughout.
"""
from datetime import datetime, timedelta
import json
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook


# Проверяет, что аудит объединения партий ссылается на существующие доставки и их итоговые партии.
def validate_coalesce_audit(cursor):
    """Read the provenance maps without changing events or batch identifiers."""
    cursor.execute("""
        SELECT count(*)
        FROM oil_stg.batch_coalesce_event_map a
        LEFT JOIN oil_stg.batch_coalesce_map m
            ON m.original_batch_id = a.original_batch_id
            AND m.coalesced_batch_id = a.coalesced_batch_id
        LEFT JOIN oil_stg.event_log e
            ON e.topic = a.topic
            AND e.kafka_partition = a.kafka_partition
            AND e.kafka_offset = a.kafka_offset
        WHERE m.original_batch_id IS NULL
            OR e.kafka_offset IS NULL
            OR e.batch_id IS DISTINCT FROM a.coalesced_batch_id
    """)
    violations = cursor.fetchone()[0]
    if violations:
        raise ValueError(f"Coalesced event provenance mismatch: {violations}")
    return violations


# Airflow передаёт контекст запуска в release(); SQL ниже выполняется на GP.
def release(**context):
    """Apply the bounded READY backlog under the registered source contract.

    A checkpoint lock drains an in-flight sink transaction. The service then
    applies all READY batches and refreshes both dependent marts atomically.
    Any reject, incomplete ledger or excess backlog rolls back the whole run.
    Selective batch_ids are rejected because they could leave DDS behind Stage.
    """
    if (context["dag_run"].conf or {}).get("batch_ids") is not None:
        raise ValueError("Selective batches are unsupported by an online complete release")
    # Подключение к исходному GP берётся из Airflow Connection webinar_greenplum, не из кода DAG.
    connection = PostgresHook(postgres_conn_id="webinar_greenplum").get_conn()
    try:
        connection.autocommit = False
        with connection.cursor() as cursor:
            cursor.execute("SET LOCAL lock_timeout='10s'")
            cursor.execute("SET LOCAL statement_timeout='180s'")
            # При наличии READY prepare_source("oil") вызывает apply_batch, затем refresh_production и refresh_downtime.
            cursor.execute("SELECT bridge_capture.prepare_source(%s)", ("oil",))
            result = cursor.fetchone()[0]
            # Читаем обе карты coalesce и исходные доставки; ошибка аудита откатывает весь source release.
            result["coalesce_audit_violations"] = validate_coalesce_audit(cursor)
        # Фиксируем применение партий и оба пересчёта одной транзакцией; до этого момента любая ошибка ведёт к rollback.
        connection.commit()
        # JSON в Logs и возвращаемом значении содержит source checks, offsets и число применённых партий.
        print(json.dumps({"stage": "source_release", "status": "ready", **result}), flush=True)
        return result
    except BaseException:
        connection.rollback()
        raise
    finally:
        connection.close()


# После включения DAG обрабатывает партии каждую минуту; одновременно допускается один run, автоматический повтор отключён.
with DAG(
    dag_id="oil_gp_release",
    description="Применение событий и пересчёт витрин нефтедобычи в Greenplum",
    start_date=datetime(2025, 1, 1), schedule="*/1 * * * *", catchup=False,
    is_paused_upon_creation=True, max_active_runs=1,
    default_args={"retries": 0, "execution_timeout": timedelta(minutes=5)},
    tags=["oil", "greenplum"],
) as dag:
    # Apply_batches_and_refresh_marts вызывает Python release(), а та — prepare_source в Greenplum.
    PythonOperator(task_id="apply_batches_and_refresh_marts", python_callable=release)
