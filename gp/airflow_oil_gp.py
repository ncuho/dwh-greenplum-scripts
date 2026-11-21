"""Manual GP release of already coalesced batches; Kafka writer must be fenced."""
from datetime import datetime,timedelta
from hashlib import sha256
from pathlib import Path
from airflow import DAG
from airflow.operators.python import PythonOperator

def release(**context):
    from airflow.hooks.base import BaseHook
    from airflow.providers.postgres.hooks.postgres import PostgresHook
    conf=context['dag_run'].conf or {}
    batches=conf.get('batch_ids')
    if conf.get('writer_paused_and_offsets_verified') is not True:
        raise ValueError('Writer pause and Kafka checkpoints must be independently verified')
    if not isinstance(batches,list) or not 1<=len(batches)<=100 or any(type(x) is not int or x<1 for x in batches):
        raise ValueError('batch_ids must contain 1–100 positive integer IDs')
    digest='cfb82a1e7313b52c6bef6d2a12b46cd55e5ade103340242ccf23e1295a92dc0b'
    ca=Path('/opt/airflow/dags/managed/gp-ca-'+digest+'.crt')
    if sha256(ca.read_bytes()).hexdigest()!=digest:raise ValueError('GP CA digest mismatch')
    cfg=BaseHook.get_connection('webinar_greenplum')
    if (cfg.host,cfg.schema,cfg.login,cfg.port)!=('160.5.219.123','og_dwh','demo_airflow_runner',5432):raise ValueError('Unexpected GP endpoint')
    if cfg.extra_dejson.get('sslmode')!='verify-full' or cfg.extra_dejson.get('sslrootcert')!=str(ca):raise ValueError('verify-full with pinned CA required')
    conn=PostgresHook(postgres_conn_id='webinar_greenplum').get_conn()
    try:
        with conn.cursor() as cur:
            for batch_id in batches:cur.execute('SELECT oil_dds.apply_batch(%s)',(batch_id,))
            cur.execute('SELECT oil_mart.refresh_production()')
            cur.execute('SELECT oil_mart.refresh_downtime()')
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:conn.close()

with DAG(dag_id='oil_gp_release',start_date=datetime(2025,1,1),schedule=None,catchup=False,
         is_paused_upon_creation=True,max_active_runs=1,default_args={'retries':0,'execution_timeout':timedelta(hours=1)},
         tags=['oil','greenplum','manual']) as dag:
    PythonOperator(task_id='apply_batches_and_refresh_marts',python_callable=release)
