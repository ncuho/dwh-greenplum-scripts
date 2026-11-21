#!/usr/bin/env bash
set -euo pipefail
export JAVA_HOME=/opt/kafka-demo/jdk
export PATH="$JAVA_HOME/bin:$PATH"
umask 077
base=/etc/kafka-demo
install -d -o kafka -g kafka -m 0750 /opt/kafka-demo/oil-plugins/oil-gp /opt/kafka-demo/oil-generator
make_cert() {
  local n=$1
  if [ -e "$base/$n.key" ] || [ -e "$base/$n.crt" ]; then
    test -s "$base/$n.key" && test -s "$base/$n.crt" || { echo "incomplete oil TLS identity" >&2; exit 1; }
    return
  fi
  openssl req -newkey rsa:3072 -nodes -keyout "$base/$n.key" -out "$base/$n.csr" -subj "/CN=$n" >/dev/null 2>&1
  printf 'extendedKeyUsage=clientAuth\n' > "$base/$n.ext"
  openssl x509 -req -in "$base/$n.csr" -CA "$base/ca.crt" -CAkey "$base/ca.key" -CAcreateserial -out "$base/$n.crt" -days 180 -extfile "$base/$n.ext" >/dev/null 2>&1
}
make_cert oil-producer
make_cert oil-connect-worker
cp "$base/ca.crt" "$base/oil-producer-ca.crt"
if [ ! -e "$base/oil-worker-store-password" ]; then openssl rand -hex 32 > "$base/oil-worker-store-password"; fi
pass=$(cat "$base/oil-worker-store-password")
if [ ! -e "$base/oil-connect-worker.p12" ]; then
 openssl pkcs12 -export -in "$base/oil-connect-worker.crt" -inkey "$base/oil-connect-worker.key" -certfile "$base/ca.crt" -name oil-worker -out "$base/oil-connect-worker.p12" -passout "pass:$pass"
fi
if [ ! -e "$base/oil-connect-trust.p12" ]; then
 keytool -importcert -noprompt -alias kafka-ca -file "$base/ca.crt" -keystore "$base/oil-connect-trust.p12" -storetype PKCS12 -storepass "$pass" >/dev/null 2>&1
fi
cat > "$base/oil-connect.properties" <<CFG
bootstrap.servers=10.77.25.20:9093
group.id=webinar-oil-connect
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.storage.StringConverter
config.storage.topic=webinar-oil-connect-config
config.storage.replication.factor=1
offset.storage.topic=webinar-oil-connect-offsets
offset.storage.replication.factor=1
status.storage.topic=webinar-oil-connect-status
status.storage.replication.factor=1
rest.advertised.host.name=127.0.0.1
rest.advertised.port=18084
listeners=http://127.0.0.1:18084
plugin.path=/opt/kafka-demo/oil-plugins
security.protocol=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=$base/oil-connect-worker.p12
ssl.keystore.password=$pass
ssl.key.password=$pass
ssl.truststore.type=PKCS12
ssl.truststore.location=$base/oil-connect-trust.p12
ssl.truststore.password=$pass
producer.security.protocol=SSL
producer.ssl.keystore.type=PKCS12
producer.ssl.keystore.location=$base/oil-connect-worker.p12
producer.ssl.keystore.password=$pass
producer.ssl.key.password=$pass
producer.ssl.truststore.type=PKCS12
producer.ssl.truststore.location=$base/oil-connect-trust.p12
producer.ssl.truststore.password=$pass
consumer.security.protocol=SSL
consumer.ssl.keystore.type=PKCS12
consumer.ssl.keystore.location=$base/oil-connect-worker.p12
consumer.ssl.keystore.password=$pass
consumer.ssl.key.password=$pass
consumer.ssl.truststore.type=PKCS12
consumer.ssl.truststore.location=$base/oil-connect-trust.p12
consumer.ssl.truststore.password=$pass
CFG
cat > /etc/systemd/system/webinar-oil-connect.service <<'UNIT'
[Unit]
Description=Webinar Oil Kafka Connect worker
After=webinar-kafka.service
Requires=webinar-kafka.service
[Service]
User=kafka
Group=kafka
Environment=JAVA_HOME=/opt/kafka-demo/jdk
Environment="KAFKA_HEAP_OPTS=-Xms128m -Xmx512m"
ExecStart=/opt/kafka-demo/current/bin/connect-distributed.sh /etc/kafka-demo/oil-connect.properties
Restart=on-failure
RestartSec=10
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
UNIT
chown kafka:kafka "$base"/oil-* /opt/kafka-demo/oil-plugins/oil-gp/* /opt/kafka-demo/oil-generator/*
chmod 600 "$base"/oil-* || true
for spec in 'webinar-oil-connect-config:1' 'webinar-oil-connect-offsets:5' 'webinar-oil-connect-status:1'; do
 name=${spec%:*}; parts=${spec#*:}
 runuser -u kafka -- env JAVA_HOME="$JAVA_HOME" /opt/kafka-demo/current/bin/kafka-topics.sh --bootstrap-server 10.77.25.20:9093 --command-config "$base/client.properties" --create --if-not-exists --topic "$name" --partitions "$parts" --replication-factor 1 --config cleanup.policy=compact
done
systemctl daemon-reload
systemctl enable --now webinar-oil-connect.service
printf '%s\n' OIL_WORKER_INSTALLED
