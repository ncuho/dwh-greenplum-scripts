#!/usr/bin/env bash
set -euo pipefail
# Runs as root on the dedicated single-node demo VM; not an HA configuration.
export JAVA_HOME=/opt/kafka-demo/jdk
export PATH="$JAVA_HOME/bin:$PATH"
test -x "$JAVA_HOME/bin/java"
id kafka >/dev/null 2>&1 || useradd --system --home /var/lib/kafka --shell /usr/sbin/nologin kafka
install -d -o kafka -g kafka -m 0750 /var/lib/kafka /var/lib/kafka/data /etc/kafka-demo /opt/kafka-demo
cd /tmp
sha512sum -c kafka.sha512
if [ ! -d /opt/kafka-demo/kafka_2.13-3.9.1 ]; then tar -xzf kafka_2.13-3.9.1.tgz -C /opt/kafka-demo; fi
ln -sfn /opt/kafka-demo/kafka_2.13-3.9.1 /opt/kafka-demo/current
chown -R kafka:kafka /opt/kafka-demo
if [ ! -e /etc/kafka-demo/ca.key ]; then
 umask 077
 openssl req -x509 -newkey rsa:3072 -nodes -keyout /etc/kafka-demo/ca.key -out /etc/kafka-demo/ca.crt -days 365 -subj '/CN=webinar-kafka-demo-CA' >/dev/null 2>&1
 openssl req -newkey rsa:3072 -nodes -keyout /etc/kafka-demo/node.key -out /etc/kafka-demo/node.csr -subj '/CN=webinar-kafka-demo' >/dev/null 2>&1
 printf 'subjectAltName=IP:10.77.25.20,IP:127.0.0.1,DNS:localhost,DNS:webinar-kafka-demo\nextendedKeyUsage=serverAuth,clientAuth\n' > /etc/kafka-demo/node.ext
 openssl x509 -req -in /etc/kafka-demo/node.csr -CA /etc/kafka-demo/ca.crt -CAkey /etc/kafka-demo/ca.key -CAcreateserial -out /etc/kafka-demo/node.crt -days 365 -extfile /etc/kafka-demo/node.ext >/dev/null 2>&1
 openssl rand -hex 32 > /etc/kafka-demo/store-password
 pass=$(cat /etc/kafka-demo/store-password)
 openssl pkcs12 -export -in /etc/kafka-demo/node.crt -inkey /etc/kafka-demo/node.key -certfile /etc/kafka-demo/ca.crt -name kafka -out /etc/kafka-demo/node.p12 -passout "pass:$pass"
 keytool -importcert -noprompt -alias demo-ca -file /etc/kafka-demo/ca.crt -keystore /etc/kafka-demo/trust.p12 -storetype PKCS12 -storepass "$pass" >/dev/null 2>&1
fi
pass=$(cat /etc/kafka-demo/store-password)
cat > /etc/kafka-demo/server.properties <<CFG
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@127.0.0.1:9094
listeners=SSL://0.0.0.0:9093,CONTROLLER://127.0.0.1:9094
advertised.listeners=SSL://10.77.25.20:9093
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,SSL:SSL
inter.broker.listener.name=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=/etc/kafka-demo/node.p12
ssl.keystore.password=$pass
ssl.key.password=$pass
ssl.truststore.type=PKCS12
ssl.truststore.location=/etc/kafka-demo/trust.p12
ssl.truststore.password=$pass
ssl.client.auth=required
log.dirs=/var/lib/kafka/data
num.partitions=3
default.replication.factor=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
group.initial.rebalance.delay.ms=0
auto.create.topics.enable=false
log.retention.hours=168
CFG
cat > /etc/kafka-demo/connect.properties <<CFG
bootstrap.servers=10.77.25.20:9093
group.id=webinar-connect
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=false
value.converter.schemas.enable=false
config.storage.topic=webinar-connect-config
config.storage.replication.factor=1
offset.storage.topic=webinar-connect-offsets
offset.storage.replication.factor=1
status.storage.topic=webinar-connect-status
status.storage.replication.factor=1
rest.advertised.host.name=127.0.0.1
listeners=http://127.0.0.1:8083
plugin.path=/opt/kafka-demo/plugins
security.protocol=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=/etc/kafka-demo/node.p12
ssl.keystore.password=$pass
ssl.key.password=$pass
ssl.truststore.type=PKCS12
ssl.truststore.location=/etc/kafka-demo/trust.p12
ssl.truststore.password=$pass
producer.security.protocol=SSL
producer.ssl.keystore.type=PKCS12
producer.ssl.keystore.location=/etc/kafka-demo/node.p12
producer.ssl.keystore.password=$pass
producer.ssl.key.password=$pass
producer.ssl.truststore.type=PKCS12
producer.ssl.truststore.location=/etc/kafka-demo/trust.p12
producer.ssl.truststore.password=$pass
consumer.security.protocol=SSL
consumer.ssl.keystore.type=PKCS12
consumer.ssl.keystore.location=/etc/kafka-demo/node.p12
consumer.ssl.keystore.password=$pass
consumer.ssl.key.password=$pass
consumer.ssl.truststore.type=PKCS12
consumer.ssl.truststore.location=/etc/kafka-demo/trust.p12
consumer.ssl.truststore.password=$pass
CFG
cat > /etc/kafka-demo/client.properties <<CFG
security.protocol=SSL
ssl.keystore.type=PKCS12
ssl.keystore.location=/etc/kafka-demo/node.p12
ssl.keystore.password=$pass
ssl.key.password=$pass
ssl.truststore.type=PKCS12
ssl.truststore.location=/etc/kafka-demo/trust.p12
ssl.truststore.password=$pass
CFG
install -d -o kafka -g kafka /opt/kafka-demo/plugins
chown -R kafka:kafka /etc/kafka-demo /var/lib/kafka
chmod 0700 /etc/kafka-demo
chmod 0600 /etc/kafka-demo/*
cat > /etc/systemd/system/webinar-kafka.service <<'UNIT'
[Unit]
Description=Webinar Kafka broker
After=network-online.target
Wants=network-online.target
[Service]
User=kafka
Group=kafka
Environment=JAVA_HOME=/opt/kafka-demo/jdk
ExecStart=/opt/kafka-demo/current/bin/kafka-server-start.sh /etc/kafka-demo/server.properties
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
UNIT
cat > /etc/systemd/system/webinar-connect.service <<'UNIT'
[Unit]
Description=Webinar Kafka Connect worker
After=webinar-kafka.service
Requires=webinar-kafka.service
[Service]
User=kafka
Group=kafka
Environment=JAVA_HOME=/opt/kafka-demo/jdk
ExecStart=/opt/kafka-demo/current/bin/connect-distributed.sh /etc/kafka-demo/connect.properties
Restart=on-failure
RestartSec=10
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
UNIT
if [ ! -f /var/lib/kafka/data/meta.properties ]; then
 cluster=$(/opt/kafka-demo/current/bin/kafka-storage.sh random-uuid)
 runuser -u kafka -- /opt/kafka-demo/current/bin/kafka-storage.sh format -t "$cluster" -c /etc/kafka-demo/server.properties
fi
systemctl daemon-reload
systemctl enable --now webinar-kafka.service
# Explicit topic creation: no business connector or data is started here.
for i in $(seq 1 60); do
 if runuser -u kafka -- /opt/kafka-demo/current/bin/kafka-topics.sh --bootstrap-server 10.77.25.20:9093 --command-config /etc/kafka-demo/client.properties --list >/dev/null 2>&1; then break; fi
 sleep 2
done
for spec in 'webinar-connect-config:1' 'webinar-connect-offsets:25' 'webinar-connect-status:5'; do
 name=${spec%:*}; parts=${spec#*:}
 runuser -u kafka -- /opt/kafka-demo/current/bin/kafka-topics.sh --bootstrap-server 10.77.25.20:9093 --command-config /etc/kafka-demo/client.properties --create --if-not-exists --topic "$name" --partitions "$parts" --replication-factor 1 --config cleanup.policy=compact
done
runuser -u kafka -- /opt/kafka-demo/current/bin/kafka-topics.sh --bootstrap-server 10.77.25.20:9093 --command-config /etc/kafka-demo/client.properties --create --if-not-exists --topic commerce.events.v1 --partitions 3 --replication-factor 1
systemctl enable --now webinar-connect.service
