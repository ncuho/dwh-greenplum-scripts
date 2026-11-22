#!/usr/bin/env bash
set -euo pipefail
cfg=/etc/kafka-demo/server.properties
backup=/etc/kafka-demo/server.properties.before-oil-authorizer-20261122
[ ! -e "$backup" ] || { echo 'Backup already exists; aborting' >&2; exit 1; }
cp -p "$cfg" "$backup"
rollback(){ code=$?; if [ "$code" -ne 0 ]; then cp -p "$backup" "$cfg"; systemctl restart webinar-kafka || true; echo 'FAILED: original broker config restored' >&2; fi; }
trap rollback EXIT
cat >> "$cfg" <<'EOF'
authorizer.class.name=org.apache.kafka.metadata.authorizer.StandardAuthorizer
allow.everyone.if.no.acl.found=true
super.users=User:ANONYMOUS;User:CN=webinar-kafka-demo
EOF
systemctl restart webinar-kafka
cmd=(runuser -u kafka -- env JAVA_HOME=/opt/kafka-demo/jdk /opt/kafka-demo/current/bin/kafka-acls.sh --bootstrap-server 10.77.25.20:9093 --command-config /etc/kafka-demo/client.properties)
for i in $(seq 1 15); do if "${cmd[@]}" --list >/dev/null 2>&1; then break; fi; sleep 2; done
"${cmd[@]}" --add --allow-principal 'User:CN=oil-connect-worker' --operation Read --topic oil.events.v1
"${cmd[@]}" --add --allow-principal 'User:CN=oil-iceberg-wave2-worker' --operation Read --topic oil.events.v1
"${cmd[@]}" --add --allow-principal 'User:CN=oil-kafka-ui-metadata' --operation Describe --topic oil.events.v1
"${cmd[@]}" --add --allow-principal 'User:CN=oil-producer' --operation Write --topic oil.events.v1
"${cmd[@]}" --list --topic oil.events.v1
systemctl is-active webinar-kafka
trap - EXIT
