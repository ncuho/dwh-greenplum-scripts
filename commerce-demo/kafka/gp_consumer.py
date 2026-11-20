#!/usr/bin/env python3
"""Bounded single-writer Kafka->GP staging consumer; never starts on import.

Explicit manual assignment avoids consumer-group rebalances. GP checkpoint is
source of truth; Kafka commit is observability only, after the GP transaction.
See README for mandatory single-instance fencing and failure handling.
"""
import argparse
import json
import os
import signal
import sys

from confluent_kafka import Consumer, TopicPartition
import psycopg


def required(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f'{name} must be configured')
    return value


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--topic', required=True)
    p.add_argument('--partitions', required=True, help='Comma-separated explicit partition IDs')
    p.add_argument('--max-messages', required=True, type=int)
    p.add_argument('--idle-timeout', type=float, default=30.0)
    args = p.parse_args()
    partitions = [int(x) for x in args.partitions.split(',')]
    if (not partitions or len(set(partitions)) != len(partitions) or min(partitions) < 0
            or args.max_messages < 1 or args.idle_timeout <= 0):
        p.error('partitions must be unique nonnegative IDs; limits must be positive')
    protocol = required('COMMERCE_KAFKA_SECURITY_PROTOCOL')
    if protocol not in ('SSL', 'SASL_SSL'):
        raise RuntimeError('Kafka requires SSL or SASL_SSL')
    cfg = {'bootstrap.servers': required('COMMERCE_KAFKA_BOOTSTRAP'),
           'security.protocol': protocol, 'group.id': required('COMMERCE_KAFKA_GROUP_ID'),
           'enable.auto.commit': False, 'enable.auto.offset.store': False,
           'auto.offset.reset': 'error', 'isolation.level': 'read_committed'}
    for env, key in [('COMMERCE_KAFKA_CA_FILE', 'ssl.ca.location'),
                     ('COMMERCE_KAFKA_CERT_FILE', 'ssl.certificate.location'),
                     ('COMMERCE_KAFKA_KEY_FILE', 'ssl.key.location'),
                     ('COMMERCE_KAFKA_SASL_MECHANISM', 'sasl.mechanism'),
                     ('COMMERCE_KAFKA_SASL_USERNAME', 'sasl.username'),
                     ('COMMERCE_KAFKA_SASL_PASSWORD', 'sasl.password')]:
        if os.environ.get(env): cfg[key] = os.environ[env]
    if protocol == 'SASL_SSL':
        for key in ('sasl.mechanism', 'sasl.username', 'sasl.password'):
            if not cfg.get(key): raise RuntimeError(f'Kafka configuration missing {key}')
    # libpq reads PGHOST/PGPORT/PGDATABASE/PGUSER and PGPASSFILE; no DSN or
    # credential is printed. Root CA and hostname verification are mandatory.
    for env in ('PGHOST', 'PGDATABASE', 'PGUSER', 'PGSSLROOTCERT'):
        required(env)
    required('PGPASSFILE')
    consumer = Consumer(cfg)
    stopping = False
    def stop(_signum, _frame):
        nonlocal stopping
        stopping = True
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        with psycopg.connect(sslmode='verify-full') as db:
            with db.cursor() as cur:
                cur.execute('SELECT kafka_partition, next_offset FROM demo_stg.kafka_checkpoint WHERE topic=%s', (args.topic,))
                positions = dict(cur.fetchall())
            if any(part not in positions for part in partitions):
                raise RuntimeError('missing explicit GP checkpoint for assigned partition')
            assigned = []
            for part in partitions:
                tp = TopicPartition(args.topic, part)
                low, high = consumer.get_watermark_offsets(tp, timeout=15, cached=False)
                offset = positions[part]
                if offset < low or offset > high:
                    raise RuntimeError(f'checkpoint outside broker retention for partition {part}: checkpoint={offset}, low={low}, high={high}')
                assigned.append(TopicPartition(args.topic, part, offset))
            db.commit()
            consumer.assign(assigned)  # static assignment: no group rebalance callbacks
            delivered = 0
            while not stopping and delivered < args.max_messages:
                msg = consumer.poll(args.idle_timeout)
                if msg is None: break
                if msg.error(): raise RuntimeError(f'Kafka poll failed: {msg.error()}')
                if msg.value() is None: raise RuntimeError('Kafka tombstone rejected; expected explicit op=D document')
                document = msg.value().decode('utf-8')
                parsed = json.loads(document)
                if not isinstance(parsed, dict) or not all(k in parsed for k in ('event_id','event_type','entity_id','entity_version','op','event_time','payload')):
                    raise RuntimeError('invalid event envelope; checkpoint remains unchanged')
                with db.transaction():
                    with db.cursor() as cur:
                        # Serializes checkpoint updates; deployment still requires external
                        # single-instance fencing (see README).
                        cur.execute('LOCK TABLE demo_stg.kafka_checkpoint IN EXCLUSIVE MODE')
                        cur.execute('SELECT next_offset FROM demo_stg.kafka_checkpoint WHERE topic=%s AND kafka_partition=%s', (msg.topic(), msg.partition()))
                        row = cur.fetchone()
                        if row is None or row[0] != msg.offset():
                            raise RuntimeError(f'offset mismatch in partition {msg.partition()}: expected {row[0] if row else None}, received {msg.offset()}; stop for investigation')
                        cur.execute("SELECT nextval('demo_stg.kafka_batch_id_seq')")
                        batch_id = cur.fetchone()[0]
                        manifest = json.dumps({'topic': msg.topic(), 'partition': msg.partition(), 'first_offset': msg.offset(), 'next_offset': msg.offset() + 1, 'count': 1}, separators=(',', ':'))
                        cur.execute("INSERT INTO demo_stg.batch_control(batch_id,source_name,status,source_manifest) VALUES (%s,%s,'OPEN',%s)", (batch_id, 'kafka:' + msg.topic(), manifest))
                        cur.execute('INSERT INTO demo_stg.kafka_event(topic,kafka_partition,kafka_offset,batch_id,event_json) VALUES (%s,%s,%s,%s,%s)', (msg.topic(), msg.partition(), msg.offset(), batch_id, document))
                        cur.execute("UPDATE demo_stg.batch_control SET status='READY' WHERE batch_id=%s", (batch_id,))
                        cur.execute('UPDATE demo_stg.kafka_checkpoint SET next_offset=%s,updated_at=now() WHERE topic=%s AND kafka_partition=%s', (msg.offset()+1, msg.topic(), msg.partition()))
                # Commit only after GP commits. On failure exit; restart seeks GP checkpoint.
                committed = consumer.commit(offsets=[TopicPartition(msg.topic(), msg.partition(), msg.offset()+1)], asynchronous=False)
                if any(tp.error is not None for tp in committed):
                    raise RuntimeError('Kafka offset commit failed; GP checkpoint remains authoritative')
                delivered += 1
            print(json.dumps({'status': 'stopped' if stopping else 'complete', 'staged_messages': delivered}))
    finally:
        consumer.close()


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        print(f'consumer failed: {type(exc).__name__}: {exc}', file=sys.stderr)
        sys.exit(1)
