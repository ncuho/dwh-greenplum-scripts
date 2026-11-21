"""Manual source release with an enforced Kafka lease and live GP writer lock."""
from datetime import datetime,timedelta
from hashlib import sha256
import json
import os
import sys
from airflow import DAG
from airflow.operators.python import PythonOperator

sys.path.insert(0,'/opt/airflow/dags/managed/oil_wave2')
from source_fence import SourceFence

def release(**context):
    conf=context['dag_run'].conf or {}
    batches=conf.get('batch_ids')
    if batches is not None and (not isinstance(batches,list) or not 1<=len(batches)<=100 or any(type(x) is not int or x<1 for x in batches) or len(set(batches))!=len(batches)):
        raise ValueError('batch_ids must contain 1–100 positive integer IDs')
    run_id=str(context.get('run_id',context['dag_run'].run_id))
    cut={'cut_id':'gp_'+sha256(run_id.encode()).hexdigest()[:24],'_capture':True}
    with SourceFence(cut,os.environ['OIL_FENCE_CONTROLLER']) as fence:
        conn=fence.conn
        with conn.cursor() as cur:
            cur.execute("SELECT kafka_partition,next_offset FROM oil_stg.kafka_checkpoint WHERE topic='oil.events.v1'")
            actual={str(k):v for k,v in cur.fetchall()}
            expected={str(p['partition']):p['end'] for p in cut['partitions']}
            if actual!=expected:raise ValueError('Source sink has not reached the Kafka cut; retry after ingestion catches up')
            if batches is None:
                cur.execute("SELECT batch_id FROM oil_stg.batch_control WHERE source_name='kafka:oil.events.v1' AND status='READY' ORDER BY batch_id LIMIT 101")
                batches=[x[0] for x in cur.fetchall()]
                if len(batches)>100:raise ValueError('More than 100 READY batches: perform the documented bounded coalesce first')
        conn.autocommit=False
        try:
            with conn.cursor() as cur:
                for batch_id in batches:
                    cur.execute('SELECT oil_dds.apply_batch(%s)',(batch_id,))
                    print(json.dumps({'stage':'source_batch','batch_id':batch_id,'status':'applied'}),flush=True)
                if batches:
                    cur.execute('SELECT oil_mart.refresh_production()')
                    cur.execute('SELECT oil_mart.refresh_downtime()')
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:conn.autocommit=True
        fence.status()
        print(json.dumps({'stage':'source_release','status':'ready','batch_count':len(batches),'cut':expected}),flush=True)

with DAG(dag_id='oil_gp_release',start_date=datetime(2025,1,1),schedule=None,catchup=False,
         is_paused_upon_creation=True,max_active_runs=1,default_args={'retries':0,'execution_timeout':timedelta(hours=1)},
         tags=['oil','greenplum','manual']) as dag:
    PythonOperator(task_id='apply_batches_and_refresh_marts',python_callable=release)
