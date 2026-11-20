#!/usr/bin/env bash
# Explicit manual use only; no workload starts when installed.
set -euo pipefail
export PYTHONPATH=/opt/kafka-demo/generator/site
export COMMERCE_KAFKA_BOOTSTRAP=10.77.25.20:9093
export COMMERCE_KAFKA_SECURITY_PROTOCOL=SSL
export COMMERCE_KAFKA_CA_FILE=/etc/kafka-demo/ca.crt
export COMMERCE_KAFKA_CERT_FILE=/etc/kafka-demo/node.crt
export COMMERCE_KAFKA_KEY_FILE=/etc/kafka-demo/node.key
exec python3 /opt/kafka-demo/generator/commerce_events.py "$@"
