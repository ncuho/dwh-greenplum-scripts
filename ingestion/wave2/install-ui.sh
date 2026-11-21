#!/usr/bin/env bash
set -euo pipefail
umask 077
id oil-kafka-ui >/dev/null 2>&1 || useradd --system --home /opt/oil-kafka-ui --shell /usr/sbin/nologin oil-kafka-ui
install -d -o root -g oil-kafka-ui -m 0750 /etc/oil-kafka-ui /opt/oil-kafka-ui
if [ -e /etc/oil-kafka-ui/client.key ] || [ -e /etc/oil-kafka-ui/client.crt ]; then
 test -s /etc/oil-kafka-ui/client.key && test -s /etc/oil-kafka-ui/client.crt || { echo 'incomplete UI TLS identity' >&2;exit 1; }
else
 openssl req -newkey rsa:3072 -nodes -keyout /etc/oil-kafka-ui/client.key -out /tmp/oil-kafka-ui.csr -subj '/CN=oil-kafka-ui-metadata' >/dev/null 2>&1
 printf 'extendedKeyUsage=clientAuth\n' > /tmp/oil-kafka-ui.ext
 openssl x509 -req -in /tmp/oil-kafka-ui.csr -CA /etc/kafka-demo/ca.crt -CAkey /etc/kafka-demo/ca.key -CAcreateserial -out /etc/oil-kafka-ui/client.crt -days 90 -extfile /tmp/oil-kafka-ui.ext >/dev/null 2>&1
 python3 -c 'from pathlib import Path;[Path(x).unlink(missing_ok=True) for x in ("/tmp/oil-kafka-ui.csr","/tmp/oil-kafka-ui.ext")]'
fi
install -o root -g oil-kafka-ui -m 0640 /etc/kafka-demo/ca.crt /etc/oil-kafka-ui/ca.crt
chown root:oil-kafka-ui /etc/oil-kafka-ui/client.crt /etc/oil-kafka-ui/client.key
chmod 0640 /etc/oil-kafka-ui/client.crt /etc/oil-kafka-ui/client.key
if [ ! -d /opt/oil-kafka-ui/site ]; then cp -a /opt/kafka-demo/generator/site /opt/oil-kafka-ui/site; fi
chown -R root:oil-kafka-ui /opt/oil-kafka-ui/site
chmod -R g+rX /opt/oil-kafka-ui/site
install -o root -g oil-kafka-ui -m 0640 /tmp/oil_kafka_ui.py /opt/oil-kafka-ui/oil_kafka_ui.py
cat > /etc/systemd/system/webinar-oil-kafka-ui.service <<'UNIT'
[Unit]
Description=Read-only oil Kafka demo dashboard
After=webinar-kafka.service
Requires=webinar-kafka.service
[Service]
User=oil-kafka-ui
Group=oil-kafka-ui
Environment=PYTHONPATH=/opt/oil-kafka-ui/site
ExecStart=/usr/bin/python3 /opt/oil-kafka-ui/oil_kafka_ui.py
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now webinar-oil-kafka-ui.service
printf '%s\n' OIL_UI_READY
