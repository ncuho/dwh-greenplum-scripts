#!/usr/bin/env bash
set -euo pipefail
export JAVA_HOME=/opt/kafka-demo/jdk
export PATH="$JAVA_HOME/bin:$PATH"
exec /opt/kafka-demo/current/bin/kafka-topics.sh \
  --bootstrap-server 10.77.25.20:9093 \
  --command-config /etc/kafka-demo/client.properties \
  --create --if-not-exists \
  --topic oil.events.v1 --partitions 3 --replication-factor 1 \
  --config retention.ms=2592000000 --config cleanup.policy=delete
