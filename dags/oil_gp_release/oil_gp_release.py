# Управляемое применение партий и пересчёт двух цепочек Greenplum. Код: oil_gp_release.py.
"""Apply complete Kafka batches and refresh both GP reports in one ordinary transaction."""
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


def apply_ready_batches(cursor):
    """Serialize the source writer, apply READY batches and rebuild both dependent reports.

    This is normal source processing. It creates no migration schema or source
    copies. The checkpoint lock serializes Kafka delivery with batch application.
    """
    cursor.execute('SELECT pg_try_advisory_xact_lock(860223191::bigint)')
    if not cursor.fetchone()[0]:
        raise RuntimeError('Source calculation already running')
    cursor.execute('LOCK TABLE oil_stg.kafka_checkpoint IN EXCLUSIVE MODE')
    cursor.execute("SELECT count(*) FROM oil_stg.batch_control WHERE source_name='kafka:oil.events.v1' AND status IN ('OPEN','FAILED')")
    if cursor.fetchone()[0]:
        raise ValueError('Incomplete or failed source batch')
    cursor.execute("SELECT batch_id FROM oil_stg.batch_control WHERE source_name='kafka:oil.events.v1' AND status='READY' ORDER BY batch_id")
    batches = [row[0] for row in cursor.fetchall()]
    if len(batches) > 100:
        raise ValueError('More than 100 READY batches; coalesce the backlog before applying')
    for batch_id in batches:
        # Главный вызов обработки GP: apply_batch разбирает события и обновляет Vault.
        cursor.execute('SELECT oil_dds.apply_batch(%s)', (batch_id,))
    if batches:
        # Расчёт добычи формирует измерения, факт и агрегат; простои используют их результат.
        cursor.execute('SELECT oil_mart.refresh_production()')
        cursor.execute('SELECT oil_mart.refresh_downtime()')
    cursor.execute('SELECT count(*) FROM oil_stg.event_reject')
    if cursor.fetchone()[0]:
        raise ValueError('Source contains rejected events')
    cursor.execute("SELECT count(*) FROM oil_stg.event_log s LEFT JOIN oil_dds.event d ON d.event_id=(s.event_json::json->>'event_id') WHERE s.topic='oil.events.v1' AND (d.event_id IS NULL OR d.event_document<>s.event_json)")
    if cursor.fetchone()[0]:
        raise ValueError('Source Stage and DDS ledger differ')
    cursor.execute("SELECT kafka_partition,next_offset FROM oil_stg.kafka_checkpoint WHERE topic='oil.events.v1' ORDER BY kafka_partition")
    return {'applied_batches': len(batches), 'partitions': [
        {'partition': row[0], 'end': row[1]} for row in cursor.fetchall()], 'source_checks': 'PASS'}


# Airflow передаёт контекст запуска в release(); SQL ниже выполняется на GP.
def release(**context):
    """Apply the bounded READY backlog and commit both source reports together.

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
            # Python явно вызывает исходные GP-функции; отдельная миграционная SQL-служба не нужна.
            result = apply_ready_batches(cursor)
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
