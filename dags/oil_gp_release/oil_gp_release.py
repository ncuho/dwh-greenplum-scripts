"""Apply complete Kafka batches and refresh both GP reports online.

The database service serializes participating writers only during this source
transaction. Kafka producers and Kafka Connect remain running throughout.
"""
from datetime import datetime, timedelta
import json
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook


def release(**context):
    """Apply the bounded READY backlog under the registered source contract.

    A checkpoint lock drains an in-flight sink transaction. The service then
    applies all READY batches and refreshes both dependent marts atomically.
    Any reject, incomplete ledger or excess backlog rolls back the whole run.
    Selective batch_ids are rejected because they could leave DDS behind Stage.
    """
    if (context["dag_run"].conf or {}).get("batch_ids") is not None:
        raise ValueError("Selective batches are unsupported by an online complete release")
    connection = PostgresHook(postgres_conn_id="webinar_greenplum").get_conn()
    try:
        connection.autocommit = False
        with connection.cursor() as cursor:
            cursor.execute("SET LOCAL lock_timeout='10s'")
            cursor.execute("SET LOCAL statement_timeout='180s'")
            cursor.execute("SELECT bridge_capture.prepare_source(%s)", ("oil",))
            result = cursor.fetchone()[0]
        connection.commit()
        print(json.dumps({"stage": "source_release", "status": "ready", **result}), flush=True)
        return result
    except BaseException:
        connection.rollback()
        raise
    finally:
        connection.close()


with DAG(
    dag_id="oil_gp_release",
    description="Применение событий и пересчёт витрин нефтедобычи в Greenplum",
    start_date=datetime(2025, 1, 1), schedule=None, catchup=False,
    is_paused_upon_creation=True, max_active_runs=1,
    default_args={"retries": 0, "execution_timeout": timedelta(minutes=5)},
    tags=["oil", "greenplum"],
) as dag:
    PythonOperator(task_id="apply_batches_and_refresh_marts", python_callable=release)
