#!/usr/bin/env python3
"""Deterministic synthetic commerce events; no network or file output without CLI action."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import random
import sys
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path
from typing import Dict, Iterator

TOPIC = 'commerce.events.v1'
NAMESPACE = uuid.UUID('8f6b870c-b1d5-4c59-bd1d-e90982be3c18')
START = datetime(2025, 1, 1, tzinfo=timezone.utc)
DIM_TIME = datetime(2024, 12, 1, tzinfo=timezone.utc)


def scenario_seed(seed: int, products: int, stores: int, shipments: int) -> int:
    """Derive the common seed for both CLI and programmatic generation."""
    signature = f'{seed}:{products}:{stores}:{shipments}'.encode()
    return int.from_bytes(hashlib.sha256(signature).digest()[:8], 'big')


def event(seed: int, event_type: str, entity_id: str, version: int,
          op: str, event_time: datetime, payload: dict) -> dict:
    name = f'commerce:{seed}:{event_type}:{entity_id}:{version}:{op}'
    return {'event_id': str(uuid.uuid5(NAMESPACE, name)), 'event_type': event_type,
            'entity_id': entity_id, 'entity_version': version, 'op': op,
            'event_time': event_time.astimezone(timezone.utc).isoformat().replace('+00:00', 'Z'),
            'payload': payload}


def product(product_id: int) -> dict:
    return {'product_id': f'P{product_id:05d}', 'product_name': f'Товар {product_id:05d}',
            'category': ('Продукты', 'Бытовые товары', 'Электроника', 'Одежда')[product_id % 4]}


def store(store_id: int) -> dict:
    return {'store_id': f'S{store_id:04d}', 'store_name': f'Магазин {store_id:04d}',
            'region': ('Север', 'Юг', 'Восток', 'Запад', 'Центр')[store_id % 5]}


def shipment(number: int, products: int, stores: int, seed: int) -> dict:
    rnd = random.Random((seed * 1000003) ^ number)
    day = START + timedelta(days=rnd.randrange(365))
    cents = rnd.randrange(1000, 200001)
    return {'shipment_id': f'H{number:09d}', 'order_id': f'O{number:09d}',
            'product_id': f'P{rnd.randrange(1, products + 1):05d}',
            'store_id': f'S{rnd.randrange(1, stores + 1):04d}',
            'business_date': day.date().isoformat(), 'quantity': rnd.randrange(1, 6),
            'unit_price': format(Decimal(cents) / Decimal(100), '.2f'), 'currency': 'RUB'}


def baseline(seed: int, products: int, stores: int, shipments: int) -> Iterator[dict]:
    for n in range(1, products + 1):
        p = product(n)
        yield event(seed, 'product', p['product_id'], 1, 'U', DIM_TIME, p)
    for n in range(1, stores + 1):
        p = store(n)
        yield event(seed, 'store', p['store_id'], 1, 'U', DIM_TIME, p)
    for n in range(1, shipments + 1):
        p = shipment(n, products, stores, seed)
        stamp = datetime.fromisoformat(p['business_date']).replace(tzinfo=timezone.utc) + timedelta(hours=12)
        yield event(seed, 'shipment', p['shipment_id'], 1, 'U', stamp, p)
        if n % 10 == 0:
            rp = {'return_id': f'R{n:09d}', 'shipment_id': p['shipment_id'],
                  'business_date': (stamp + timedelta(days=2)).date().isoformat(),
                  'quantity': 1, 'unit_price': p['unit_price'], 'currency': 'RUB'}
            yield event(seed, 'return', rp['return_id'], 1, 'U', stamp + timedelta(days=2), rp)


def delta(seed: int, products: int, stores: int, shipments: int) -> Iterator[dict]:
    """Correction, delete, late dimension history and exact replay; requires baseline >= 10 shipments."""
    if shipments < 10:
        raise ValueError('delta requires at least 10 baseline shipments')
    p = shipment(1, products, stores, seed)
    stamp = START + timedelta(days=366, hours=10)
    corrected = dict(p, quantity=p['quantity'] + 1)
    yield event(seed, 'shipment', p['shipment_id'], 2, 'U', stamp, corrected)
    original = shipment(10, products, stores, seed)
    ret = {'return_id': 'R000000010', 'shipment_id': original['shipment_id'],
           'business_date': (datetime.fromisoformat(original['business_date']) + timedelta(days=2)).date().isoformat(),
           'quantity': 1, 'unit_price': original['unit_price'], 'currency': 'RUB'}
    yield event(seed, 'return', ret['return_id'], 2, 'D', stamp + timedelta(minutes=1), ret)
    changed = dict(product(1), category='Сезонные товары')
    yield event(seed, 'product', changed['product_id'], 2, 'U',
                datetime(2025, 7, 1, tzinfo=timezone.utc), changed)
    # Replay must reproduce every field, including event_id and event_time.
    yield event(seed, 'shipment', p['shipment_id'], 2, 'U', stamp, corrected)


def encode(e: dict) -> str:
    return json.dumps(e, ensure_ascii=False, separators=(',', ':'))


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--phase', required=True, choices=('baseline', 'delta'))
    p.add_argument('--seed', type=int, default=20261120)
    p.add_argument('--products', type=int, default=100)
    p.add_argument('--stores', type=int, default=20)
    p.add_argument('--shipments', type=int, default=10000)
    p.add_argument('--topic', default=TOPIC)
    dest = p.add_mutually_exclusive_group(required=True)
    dest.add_argument('--output', help='Create a NEW UTF-8 NDJSON file; existing files are not overwritten')
    dest.add_argument('--kafka', action='store_true', help='Publish using secure configuration from environment')
    args = p.parse_args()
    if min(args.products, args.stores, args.shipments) < 1:
        p.error('products, stores and shipments must all be positive')
    if args.phase == 'delta' and args.shipments < 10:
        p.error('delta requires the matching baseline with at least 10 shipments')
    # Fix the entire generation contract into the event-ID namespace. Changing
    # any dimension cannot silently reuse IDs with different payloads.
    derived_seed = scenario_seed(args.seed, args.products, args.stores, args.shipments)
    events = (baseline if args.phase == 'baseline' else delta)(derived_seed, args.products, args.stores, args.shipments)
    if args.output:
        count = 0
        with Path(args.output).open('x', encoding='utf-8') as f:
            for e in events:
                f.write(encode(e) + '\n'); count += 1
        print(json.dumps({'status': 'created', 'records': count, 'phase': args.phase}))
        return
    bootstrap = os.environ.get('COMMERCE_KAFKA_BOOTSTRAP', '')
    protocol = os.environ.get('COMMERCE_KAFKA_SECURITY_PROTOCOL', '')
    if not bootstrap or protocol not in ('SSL', 'SASL_SSL'):
        p.error('COMMERCE_KAFKA_BOOTSTRAP and secure COMMERCE_KAFKA_SECURITY_PROTOCOL=SSL|SASL_SSL are required')
    try:
        from confluent_kafka import Producer
    except ImportError:
        raise SystemExit('Install the pinned Kafka client in the dedicated environment')
    config = {'bootstrap.servers': bootstrap, 'security.protocol': protocol, 'enable.idempotence': True,
              'acks': 'all', 'delivery.timeout.ms': 120000, 'client.id': 'commerce-demo-generator'}
    for env_name, kafka_name in [('COMMERCE_KAFKA_CA_FILE','ssl.ca.location'),
                                 ('COMMERCE_KAFKA_SASL_MECHANISM','sasl.mechanism'),
                                 ('COMMERCE_KAFKA_SASL_USERNAME','sasl.username'),
                                 ('COMMERCE_KAFKA_SASL_PASSWORD','sasl.password')]:
        if os.environ.get(env_name): config[kafka_name] = os.environ[env_name]
    if protocol == 'SASL_SSL' and not all(k in config for k in ('sasl.mechanism','sasl.username','sasl.password')):
        p.error('SASL_SSL requires SASL mechanism, username and password from environment')
    producer = Producer(config); state: Dict[str, int] = {'success': 0, 'error': 0}
    def delivered(error, _message):
        state['error' if error else 'success'] += 1
    for e in events:
        value = encode(e).encode('utf-8')
        while True:
            try:
                producer.produce(args.topic, key=e['event_type'] + ':' + e['entity_id'], value=value, on_delivery=delivered)
                break
            except BufferError:
                producer.poll(1.0)
        producer.poll(0)
    remaining = producer.flush(120)
    print(json.dumps({'status': 'ok' if not remaining and not state['error'] else 'error',
                      'delivered': state['success'], 'failed': state['error'], 'pending': remaining}))
    if remaining or state['error']: sys.exit(1)


if __name__ == '__main__':
    main()
