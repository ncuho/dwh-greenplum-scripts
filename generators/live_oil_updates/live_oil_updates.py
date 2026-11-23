"""Emit continuous versioned production corrections before and during migration."""
import argparse
from datetime import datetime, timezone
from decimal import Decimal
import importlib.util
import json
import signal
import time
from pathlib import Path


def load_source(path):
    """Reuse the deployed source's envelope, encoding and baseline key formulas."""
    spec = importlib.util.spec_from_file_location('oil_events', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    """Publish a bounded-range correction every interval until the operator stops it."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--interval', type=float, default=10)
    parser.add_argument('--seed', type=int, default=42)
    parser.add_argument('--state', default='/tmp/oil-live-production.json')
    parser.add_argument('--source', default='/opt/kafka-demo/oil-generator/oil_events.py')
    parser.add_argument('--resume', action='store_true')
    args = parser.parse_args()
    if args.interval < 2:
        parser.error('interval must be at least two seconds')
    source = load_source(args.source)
    baseline = source.production(1, 0, source.scenario_seed(args.seed, 5, 40, 365))
    path = Path(args.state)
    if path.exists() and not args.resume:
        parser.error('State exists; inspect it and use --resume to continue the same stream')
    state = json.loads(path.read_text()) if path.exists() else {'sequence': 0, 'last_version': 1, 'pending': None, 'seed': args.seed}
    if state.get('seed') != args.seed:
        parser.error('Cannot resume a different source seed')
    from confluent_kafka import Producer
    producer = Producer({'bootstrap.servers': '10.77.25.20:9093', 'security.protocol': 'SSL',
                         'ssl.ca.location': '/etc/kafka-demo/oil-producer-ca.crt',
                         'ssl.certificate.location': '/etc/kafka-demo/oil-producer.crt',
                         'ssl.key.location': '/etc/kafka-demo/oil-producer.key',
                         'enable.idempotence': True, 'acks': 'all'})
    stop = [False]

    def finish(signum, frame):
        """Stop after the current delivery acknowledgement without killing an in-flight flush."""
        stop[0] = True

    def save():
        """Persist pending events before delivery so a restart replays the same event_id."""
        temporary = path.with_suffix('.tmp')
        temporary.write_text(json.dumps(state, ensure_ascii=False))
        temporary.replace(path)

    signal.signal(signal.SIGINT, finish)
    signal.signal(signal.SIGTERM, finish)
    while not stop[0]:
        if state['pending'] is None:
            sequence = state['sequence'] + 1
            version = max(int(time.time() * 1000), state['last_version'] + 1)
            payload = dict(baseline)
            # Small upward/downward corrections preserve the same business grain and realistic daily quantity.
            payload['oil_tonnes'] = format(Decimal(baseline['oil_tonnes']) + Decimal(sequence % 10 + 1) / 100, '.3f')
            document = source.event(args.seed, 'production_day', payload['production_id'], version, 'U',
                                    datetime.now(timezone.utc).isoformat(), payload)
            state['pending'] = {'sequence': sequence, 'document': source.encode(document), 'version': version}
            save()
        pending = state['pending']
        delivered = []

        def acknowledge(error, message):
            """Record the broker-confirmed offset, never a locally guessed transport position."""
            if error:
                delivered.append({'error': str(error)})
            else:
                delivered.append({'partition': message.partition(), 'offset': message.offset()})

        producer.produce('oil.events.v1', key='production_day:' + baseline['production_id'],
                         value=pending['document'], on_delivery=acknowledge)
        if producer.flush(30) != 0 or not delivered or 'error' in delivered[0]:
            raise RuntimeError('Delivery outcome uncertain; pending event is saved for an exact replay')
        state.update(sequence=pending['sequence'], last_version=pending['version'], pending=None)
        save()
        print(json.dumps({'sequence': state['sequence'], 'entity_version': state['last_version'], **delivered[0]}), flush=True)
        deadline = time.monotonic() + args.interval
        while not stop[0] and time.monotonic() < deadline:
            time.sleep(min(0.5, max(0, deadline - time.monotonic())))
    producer.flush(30)
    print(json.dumps({'status': 'STOPPED', 'delivered': state['sequence'], 'state_file': str(path)}))


if __name__ == '__main__':
    main()
