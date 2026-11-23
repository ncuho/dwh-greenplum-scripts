#!/usr/bin/env python3
# Программный источник событий месторождений, скважин, добычи и простоев. Baseline воспроизводим по seed; delta включает correction, replay, delete, late arrival и версию well.
"""Reproducible oilfield events. Import has no I/O; publishing is explicit."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import random
import sys
import uuid
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path
from typing import Iterator

TOPIC = "oil.events.v1"
NAMESPACE = uuid.UUID("e1d91220-8131-4fde-ab2e-15b2e341c468")
START = date(2025, 1, 1)
DIM_TIME = "2024-12-01T00:00:00Z"
DELTA_TIME = "2026-01-02T12:00:00Z"


def scenario_seed(seed: int, fields: int, wells: int, days: int) -> int:
    """Получает стабильный seed из параметров кейса; иной размер набора создаёт другой поток."""
    raw = f"oil-events-v1:{seed}:{fields}:{wells}:{days}".encode()
    return int.from_bytes(hashlib.sha256(raw).digest()[:8], "big")


def encode(value: dict) -> str:
    """Сериализует событие каноническим JSON UTF-8; формат важен для повторов и hashdiff."""
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def event(
    seed: int,
    event_type: str,
    entity_id: str,
    version: int,
    op: str,
    event_time: str,
    payload: dict,
) -> dict:
    """Формирует конверт бизнес-события с версией, операцией и стабильным event_id."""
    body = {
        "schema_version": 1,
        "event_type": event_type,
        "entity_id": entity_id,
        "entity_version": version,
        "op": op,
        "event_time": event_time,
        "payload": payload,
    }
    digest = hashlib.sha256(encode(body).encode("utf-8")).hexdigest()
    return {"event_id": str(uuid.uuid5(NAMESPACE, f"{seed}:{digest}")), **body}


def field(n: int) -> dict:
    """Формирует атрибуты месторождения по его бизнес-ключу."""
    return {
        "field_id": f"F{n:03d}",
        "field_name": f"Месторождение {n:03d}",
        "region": ("Северный", "Восточный", "Южный")[(n - 1) % 3],
    }


def well(n: int, fields: int) -> dict:
    """Формирует скважину и её принадлежность месторождению с датой начала действия."""
    return {
        "well_id": f"W{n:05d}",
        "field_id": f"F{1 + (n - 1) % fields:03d}",
        "well_name": f"Скважина {n:05d}",
        "valid_from": "2024-12-01",
        "status": "ACTIVE",
    }


def production(n: int, day: int, seed: int) -> dict:
    """Формирует суточный факт добычи в тоннах с точной шкалой Decimal."""
    dt = START + timedelta(days=day)
    rnd = random.Random((seed ^ (n * 1000003) ^ (day * 9176)))
    tonnes = (Decimal(rnd.randrange(4000, 45001)) / Decimal(1000)).quantize(
        Decimal("0.001")
    )
    return {
        "production_id": f"W{n:05d}_{dt:%Y%m%d}",
        "well_id": f"W{n:05d}",
        "production_date": dt.isoformat(),
        "oil_tonnes": format(tonnes, ".3f"),
        "status": "ACTIVE",
    }


def downtime(n: int, day: int) -> dict:
    """Формирует интервал простоя, его причину и ссылку на скважину."""
    dt = START + timedelta(days=day)
    start = datetime(dt.year, dt.month, dt.day, 8, tzinfo=timezone.utc)
    end = start + timedelta(hours=2 + n % 5)
    fmt = lambda x: x.isoformat().replace("+00:00", "Z")
    return {
        "downtime_id": f"DW{n:05d}_{dt:%Y%m%d}",
        "well_id": f"W{n:05d}",
        "start_at": fmt(start),
        "end_at": fmt(end),
        "reason": ("EQUIPMENT", "POWER", "PLANNED")[(n - 1) % 3],
    }


def baseline(seed: int, fields: int, wells: int, days: int) -> Iterator[dict]:
    """Формирует исходную историю: справочники прежде фактов, затем события по дням."""
    for n in range(1, fields + 1):
        p = field(n)
        yield event(seed, "field", p["field_id"], 1, "U", DIM_TIME, p)
    for n in range(1, wells + 1):
        p = well(n, fields)
        yield event(seed, "well", p["well_id"], 1, "U", DIM_TIME, p)
    for day in range(days):
        stamp = (START + timedelta(days=day)).isoformat() + "T12:00:00Z"
        for n in range(1, wells + 1):
            p = production(n, day, seed)
            yield event(seed, "production_day", p["production_id"], 1, "U", stamp, p)
            if day % 17 == 0:
                d = downtime(n, day)
                yield event(seed, "downtime", d["downtime_id"], 1, "U", stamp, d)


def delta(seed: int, fields: int, wells: int, days: int) -> Iterator[dict]:
    # One correction, one logical delete, a late valid-time dimension version,
    # A late arrival and a byte-identical replay. All refer to the same baseline.
    """Формирует коррекцию, удаление, поздние версии и точный replay относительно того же baseline."""
    original = production(1, 0, seed)
    corrected = dict(
        original,
        oil_tonnes=format(Decimal(original["oil_tonnes"]) + Decimal("1.250"), ".3f"),
    )
    update = event(
        seed,
        "production_day",
        corrected["production_id"],
        2,
        "U",
        DELTA_TIME,
        corrected,
    )
    yield update
    d = downtime(1, 0)
    yield event(seed, "downtime", d["downtime_id"], 2, "D", DELTA_TIME, d)
    w = dict(
        well(1, fields), valid_from="2025-07-01", well_name="Скважина 00001 (уточнение)"
    )
    yield event(seed, "well", w["well_id"], 2, "U", DELTA_TIME, w)
    # Day index 1 is not used by the every-17-days baseline interval.
    late = downtime(1, 1)
    yield event(seed, "downtime", late["downtime_id"], 1, "U", DELTA_TIME, late)
    yield update


def main() -> None:
    """Точка входа: Reproducible oilfield events. Import has no I/O; publishing is explicit. Импорт модуля сам по себе эту операцию не запускает."""
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--phase", required=True, choices=("baseline", "delta"))
    p.add_argument("--seed", type=int, default=20261120)
    p.add_argument("--fields", type=int, default=5)
    p.add_argument("--wells", type=int, default=40)
    p.add_argument("--days", type=int, default=365)
    p.add_argument("--topic", default=TOPIC)
    dest = p.add_mutually_exclusive_group(required=True)
    dest.add_argument("--output", help="Create a new UTF-8 NDJSON file; no overwrite")
    dest.add_argument(
        "--kafka", action="store_true", help="Explicit publication to Kafka"
    )
    args = p.parse_args()
    if not (1 <= args.fields <= args.wells <= 100000 and 2 <= args.days <= 365):
        p.error("require 1 <= fields <= wells <= 100000 and 2 <= days <= 365")
    derived = scenario_seed(args.seed, args.fields, args.wells, args.days)
    events = (baseline if args.phase == "baseline" else delta)(
        derived, args.fields, args.wells, args.days
    )
    if args.output:
        count = 0
        with Path(args.output).open("x", encoding="utf-8") as f:
            for e in events:
                f.write(encode(e) + "\n")
                count += 1
        print(json.dumps({"status": "created", "phase": args.phase, "records": count}))
        return
    bootstrap = os.environ.get("OIL_KAFKA_BOOTSTRAP", "")
    protocol = os.environ.get("OIL_KAFKA_SECURITY_PROTOCOL", "")
    if not bootstrap or protocol not in ("SSL", "SASL_SSL"):
        p.error(
            "OIL_KAFKA_BOOTSTRAP and OIL_KAFKA_SECURITY_PROTOCOL=SSL|SASL_SSL are required"
        )
    try:
        from confluent_kafka import Producer
    except ImportError:
        raise SystemExit("Install the pinned Kafka client in the dedicated environment")
    cfg = {
        "bootstrap.servers": bootstrap,
        "security.protocol": protocol,
        "enable.idempotence": True,
        "acks": "all",
        "delivery.timeout.ms": 120000,
        "client.id": "oil-events-producer",
    }
    for env, key in [
        ("OIL_KAFKA_CA_FILE", "ssl.ca.location"),
        ("OIL_KAFKA_CERT_FILE", "ssl.certificate.location"),
        ("OIL_KAFKA_KEY_FILE", "ssl.key.location"),
        ("OIL_KAFKA_SASL_MECHANISM", "sasl.mechanism"),
        ("OIL_KAFKA_SASL_USERNAME", "sasl.username"),
        ("OIL_KAFKA_SASL_PASSWORD", "sasl.password"),
    ]:
        if os.environ.get(env):
            cfg[key] = os.environ[env]
    if not cfg.get("ssl.ca.location"):
        p.error("OIL_KAFKA_CA_FILE is required for broker certificate verification")
    if protocol == "SSL" and not all(
        k in cfg for k in ("ssl.certificate.location", "ssl.key.location")
    ):
        p.error("SSL requires a dedicated producer client certificate and key")
    if protocol == "SASL_SSL" and not all(
        k in cfg for k in ("sasl.mechanism", "sasl.username", "sasl.password")
    ):
        p.error("SASL_SSL requires mechanism, username and password from environment")
    producer = Producer(cfg)
    state = {"delivered": 0, "failed": 0}

    def delivered(error, _msg):
        """Обрабатывает подтверждение брокера и учитывает успешные и неуспешные доставки."""
        state["failed" if error else "delivered"] += 1

    for e in events:
        while True:
            try:
                # Отправляем JSON в Kafka; GP-функции вызовет отдельный Airflow release после приёма события sink-коннектором.
                producer.produce(
                    args.topic,
                    key=e["event_type"] + ":" + e["entity_id"],
                    value=encode(e).encode("utf-8"),
                    on_delivery=delivered,
                )
                break
            except BufferError:
                producer.poll(1.0)
        producer.poll(0)
    pending = producer.flush(120)
    print(
        json.dumps(
            {
                "status": "ok" if not pending and not state["failed"] else "error",
                "delivered": state["delivered"],
                "failed": state["failed"],
                "pending": pending,
            }
        )
    )
    if pending or state["failed"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
