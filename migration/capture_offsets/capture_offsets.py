#!/usr/bin/env python3
"""Capture Kafka low/high offsets only; this is NOT a Greenplum-consistent cut."""
import argparse
import json
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path


def main():
    """Точка входа: Capture Kafka low/high offsets only; this is NOT a Greenplum-consistent cut. Импорт модуля сам по себе эту операцию не запускает."""
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--topic", default="oil.events.v1")
    p.add_argument(
        "--output", required=True, help="New manifest path; never overwritten"
    )
    args = p.parse_args()
    bootstrap = os.environ.get("OIL_KAFKA_BOOTSTRAP", "")
    protocol = os.environ.get("OIL_KAFKA_SECURITY_PROTOCOL", "")
    if not bootstrap or protocol not in ("SSL", "SASL_SSL"):
        p.error("secure Kafka bootstrap and SSL or SASL_SSL are required")
    from confluent_kafka import Consumer, TopicPartition

    cfg = {
        "bootstrap.servers": bootstrap,
        "security.protocol": protocol,
        "group.id": "oil-offset-read-" + uuid.uuid4().hex,
        "enable.auto.commit": False,
        "enable.auto.offset.store": False,
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
        p.error("SSL requires a dedicated client certificate and key")
    if protocol == "SASL_SSL" and not all(
        k in cfg for k in ("sasl.mechanism", "sasl.username", "sasl.password")
    ):
        p.error("SASL_SSL requires mechanism, username and password")
    consumer = Consumer(cfg)
    try:
        # Full metadata avoids a topic-specific lookup that can auto-create a
        # missing topic on brokers with auto.create.topics.enable=true.
        meta = consumer.list_topics(timeout=15)
        topic = meta.topics.get(args.topic)
        if topic is None or topic.error or not topic.partitions:
            raise RuntimeError("topic unavailable or has no partitions")
        offsets = []
        for part in sorted(topic.partitions):
            lo, hi = consumer.get_watermark_offsets(
                TopicPartition(args.topic, part), timeout=15, cached=False
            )
            if lo < 0 or hi < lo:
                raise RuntimeError("invalid watermark")
            offsets.append(
                {
                    "partition": part,
                    "low_offset_inclusive": lo,
                    "high_next_offset_exclusive": hi,
                }
            )
        manifest = {
            "format_version": 1,
            "kind": "kafka_watermarks_only",
            "captured_at_utc": datetime.now(timezone.utc).isoformat(),
            "cluster_id": getattr(meta, "cluster_id", None),
            "topic": args.topic,
            "partitions": offsets,
            "gp_consistent_cut_proven": False,
            "warning": "Requires producer freeze, GP staging/apply fence and a separately verified GP snapshot.",
        }
        with Path(args.output).open("x", encoding="utf-8") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(
            json.dumps(
                {
                    "status": "created",
                    "partitions": len(offsets),
                    "gp_consistent_cut_proven": False,
                }
            )
        )
    finally:
        consumer.close()


if __name__ == "__main__":
    main()
