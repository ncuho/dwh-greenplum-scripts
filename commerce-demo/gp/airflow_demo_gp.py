"""Manual source-side batch processing; deployment and connection are not configured.

Requires Airflow's postgres provider and an operator-provisioned connection named
webinar_greenplum with least-privilege credentials. This DAG does not migrate data.
"""
from datetime import datetime
from hashlib import sha256
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator


def apply_batch(**context):
    from airflow.providers.postgres.hooks.postgres import PostgresHook

    value = (context['dag_run'].conf or {}).get('batch_id')
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise ValueError('dag_run.conf.batch_id must be a positive integer')
    from airflow.hooks.base import BaseHook

    ca_sha256 = 'cfb82a1e7313b52c6bef6d2a12b46cd55e5ade103340242ccf23e1295a92dc0b'
    ca_path = Path('/opt/airflow/dags/managed/gp-ca-' + ca_sha256 + '.crt')
    if sha256(ca_path.read_bytes()).hexdigest() != ca_sha256:
        raise ValueError('Greenplum CA certificate does not match the pinned digest')
    config = BaseHook.get_connection('webinar_greenplum')
    if (config.host, config.schema, config.login, config.port) != (
        '160.5.219.123', 'og_dwh', 'demo_airflow_runner', 5432
    ) or config.extra_dejson.get('sslmode') != 'verify-full' or config.extra_dejson.get('sslrootcert') != str(ca_path):
        raise ValueError('Greenplum connection must use the approved TLS endpoint and CA')
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
