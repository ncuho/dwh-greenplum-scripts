#!/usr/bin/env bash
# Explicit manual invocation only. The script does not run during installation.
set -euo pipefail
export PYTHONPATH=/opt/kafka-demo/generator/site
export OIL_KAFKA_BOOTSTRAP=10.77.25.20:9093
export OIL_KAFKA_SECURITY_PROTOCOL=SSL
export OIL_KAFKA_CA_FILE=/etc/kafka-demo/oil-producer-ca.crt
export OIL_KAFKA_CERT_FILE=/etc/kafka-demo/oil-producer.crt
export OIL_KAFKA_KEY_FILE=/etc/kafka-demo/oil-producer.key
exec python3 /opt/kafka-demo/oil-generator/oil_events.py "$@"
