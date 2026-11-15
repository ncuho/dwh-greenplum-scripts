"""Prepared manual orchestration; not installed or executed on any Airflow instance."""
from datetime import datetime, timezone

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

from batch_parameters import validate_batch


def run_batch(**context):
    conf = context["dag_run"].conf or {}
    batch_id, start, end, run_id = validate_batch(conf)
    # The connection and permissions must be provisioned separately.
    hook = PostgresHook(postgres_conn_id="greenplum_business_write")
    with hook.get_conn() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT etl.run_daily_batch(%s, %s, %s, %s)",
                (batch_id, start, end, run_id),
            )
            processed_count = cursor.fetchone()[0]
        connection.commit()
    return processed_count


with DAG(
    dag_id="gp_business_batch_manual",
    description="Manually requested Greenplum business batch",
    start_date=datetime(2025, 1, 1, tzinfo=timezone.utc),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 0},
) as dag:
    PythonOperator(task_id="rebuild_business_marts", python_callable=run_batch)
