#!/usr/bin/env bash
set -euo pipefail
export JAVA_HOME=/opt/kafka-demo/jdk
export PATH="$JAVA_HOME/bin:$PATH"
umask 077
base=/etc/kafka-demo
n=oil-iceberg-wave2-worker
if [ -e "$base/$n.key" ] || [ -e "$base/$n.crt" ]; then
 test -s "$base/$n.key" && test -s "$base/$n.crt" || { echo 'incomplete worker TLS identity' >&2; exit 1; }
else
 openssl req -newkey rsa:3072 -nodes -keyout "$base/$n.key" -out "$base/$n.csr" -subj "/CN=$n" >/dev/null 2>&1
 printf 'extendedKeyUsage=clientAuth\n' > "$base/$n.ext"
 openssl x509 -req -in "$base/$n.csr" -CA "$base/ca.crt" -CAkey "$base/ca.key" -CAcreateserial -out "$base/$n.crt" -days 180 -extfile "$base/$n.ext" >/dev/null 2>&1
fi
if [ ! -e "$base/$n-store-password" ]; then openssl rand -hex 32 > "$base/$n-store-password"; fi
pass=$(cat "$base/$n-store-password")
if [ ! -e "$base/$n.p12" ]; then openssl pkcs12 -export -in "$base/$n.crt" -inkey "$base/$n.key" -certfile "$base/ca.crt" -name oil-wave2 -out "$base/$n.p12" -passout "pass:$pass"; fi
if [ ! -e "$base/$n-trust.p12" ]; then keytool -importcert -noprompt -alias kafka-ca -file "$base/ca.crt" -keystore "$base/$n-trust.p12" -storetype PKCS12 -storepass "$pass" >/dev/null 2>&1; fi
cat > "$base/$n.properties" <<CFG
bootstrap.servers=10.77.25.20:9093
group.id=webinar-oil-wave2-connect
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.storage.StringConverter
config.storage.topic=webinar-oil-wave2-connect-config
config.storage.replication.factor=1
offset.storage.topic=webinar-oil-wave2-connect-offsets
offset.storage.replication.factor=1
status.storage.topic=webinar-oil-wave2-connect-status
status.storage.replication.factor=1
rest.advertised.host.name=127.0.0.1
rest.advertised.port=18085
listeners=http://127.0.0.1:18085
plugin.path=/opt/kafka-demo/plugins
security.protocol=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=$base/$n.p12
ssl.keystore.password=$pass
ssl.key.password=$pass
ssl.truststore.type=PKCS12
ssl.truststore.location=$base/$n-trust.p12
ssl.truststore.password=$pass
producer.security.protocol=SSL
producer.ssl.keystore.type=PKCS12
producer.ssl.keystore.location=$base/$n.p12
producer.ssl.keystore.password=$pass
producer.ssl.key.password=$pass
producer.ssl.truststore.type=PKCS12
producer.ssl.truststore.location=$base/$n-trust.p12
producer.ssl.truststore.password=$pass
consumer.security.protocol=SSL
consumer.ssl.keystore.type=PKCS12
consumer.ssl.keystore.location=$base/$n.p12
consumer.ssl.keystore.password=$pass
consumer.ssl.key.password=$pass
consumer.ssl.truststore.type=PKCS12
consumer.ssl.truststore.location=$base/$n-trust.p12
consumer.ssl.truststore.password=$pass
CFG
cat > /etc/systemd/system/webinar-oil-wave2-connect.service <<'UNIT'
[Unit]
Description=Webinar oil wave 2 Iceberg Connect worker
After=webinar-kafka.service
Requires=webinar-kafka.service
[Service]
User=kafka
Group=kafka
Environment=JAVA_HOME=/opt/kafka-demo/jdk
Environment="KAFKA_HEAP_OPTS=-Xms128m -Xmx512m"
Environment="KAFKA_OPTS=-Djavax.net.ssl.trustStore=/etc/kafka-demo/iceberg-truststore.p12 -Djavax.net.ssl.trustStorePassword=changeit"
ExecStart=/opt/kafka-demo/current/bin/connect-distributed.sh /etc/kafka-demo/oil-iceberg-wave2-worker.properties
Restart=on-failure
RestartSec=10
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
UNIT
chown kafka:kafka "$base"/$n*
chmod 600 "$base"/$n*
for spec in 'webinar-oil-wave2-connect-config:1' 'webinar-oil-wave2-connect-offsets:5' 'webinar-oil-wave2-connect-status:1'; do
 name=${spec%:*}; parts=${spec#*:}
 runuser -u kafka -- env JAVA_HOME="$JAVA_HOME" /opt/kafka-demo/current/bin/kafka-topics.sh --bootstrap-server 10.77.25.20:9093 --command-config "$base/client.properties" --create --if-not-exists --topic "$name" --partitions "$parts" --replication-factor 1 --config cleanup.policy=compact
done
runuser -u kafka -- env JAVA_HOME="$JAVA_HOME" /opt/kafka-demo/current/bin/kafka-topics.sh --bootstrap-server 10.77.25.20:9093 --command-config "$base/client.properties" --create --if-not-exists --topic webinar-oil-wave2-iceberg-control --partitions 1 --replication-factor 1
systemctl daemon-reload
systemctl enable --now webinar-oil-wave2-connect.service
printf '%s\n' OIL_WAVE2_WORKER_READY
