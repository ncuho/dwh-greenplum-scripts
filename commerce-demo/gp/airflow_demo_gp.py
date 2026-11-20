"""Manual source-side batch processing; deployment and connection are not configured.

Requires Airflow's postgres provider and an operator-provisioned connection named
webinar_greenplum with least-privilege credentials. This DAG does not migrate data.
"""
from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator


def apply_batch(**context):
    from airflow.providers.postgres.hooks.postgres import PostgresHook

    value = (context['dag_run'].conf or {}).get('batch_id')
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise ValueError('dag_run.conf.batch_id must be a positive integer')
    conn = PostgresHook(postgres_conn_id='webinar_greenplum').get_conn()
    try:
        with conn.cursor() as cursor:
            cursor.execute('SELECT demo_ods.apply_batch(%s)', (value,))
            cursor.execute('SELECT demo_dm.rebuild()')
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


with DAG(
    dag_id='webinar_commerce_greenplum_batch',
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=['webinar', 'source', 'manual'],
) as dag:
    PythonOperator(task_id='apply_batch_and_rebuild', python_callable=apply_batch)
