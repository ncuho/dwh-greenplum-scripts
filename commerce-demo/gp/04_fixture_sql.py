#!/usr/bin/env python3
"""Emit a local synthetic fixture SQL; no DB connections and no real Kafka offsets."""
import argparse
import importlib.util
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--generator', type=Path, required=True)
parser.add_argument('--batch-id', type=int, default=1)
parser.add_argument('--seed', type=int, default=42)
parser.add_argument('--products', type=int, default=20)
parser.add_argument('--stores', type=int, default=8)
parser.add_argument('--shipments', type=int, default=500)
a = parser.parse_args()
if min(a.batch_id, a.products, a.stores, a.shipments) < 1:
    parser.error('batch ID and counts must be positive')
spec = importlib.util.spec_from_file_location('commerce_events', a.generator)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
seed = mod.scenario_seed(a.seed, a.products, a.stores, a.shipments)
def quote(value):
    return "'" + value.replace("'", "''") + "'"
print('-- Synthetic positions are NOT Kafka offsets. Run only on an isolated demo instance.')
print('BEGIN;')
manifest = json.dumps({'kind': 'synthetic_fixture', 'seed': a.seed, 'derived_seed': seed,
                       'products': a.products, 'stores': a.stores, 'shipments': a.shipments}, sort_keys=True)
print("INSERT INTO demo_stg.batch_control(batch_id,source_name,status,source_manifest) VALUES (%d,'synthetic_fixture','OPEN',%s);" % (a.batch_id, quote(manifest)))
for offset, event in enumerate(mod.baseline(seed, a.products, a.stores, a.shipments)):
    document = json.dumps(event, ensure_ascii=False, separators=(',', ':'))
    print("INSERT INTO demo_stg.kafka_event(topic,kafka_partition,kafka_offset,batch_id,event_json) VALUES ('fixture.baseline',0,%d,%d,%s);" % (offset,a.batch_id,quote(document)))
print("UPDATE demo_stg.batch_control SET status='READY' WHERE batch_id=%d;" % a.batch_id)
print('SELECT demo_ods.apply_batch(%d);' % a.batch_id)
print('SELECT demo_dm.rebuild();')
print('COMMIT;')
