#!/usr/bin/env python3
"""Provision only the oil staging GP role and a 0600 VM secret; no event writes."""
import hashlib, secrets, subprocess
from pathlib import Path

import os

conf = Path(os.environ["OIL_GP_SSH_CONFIG"]).expanduser().resolve()

vm = [
    "ssh",
    "-F",
    str(conf),
    "-o",
    "ProxyJump=gp-demo-coordinator",
    "-i",
    str(Path.home() / ".ssh/vk_migration_demo_20261115_rsa"),
    "ubuntu@10.77.25.20",
]
gp = ["ssh", "-F", str(conf), "gp-demo-coordinator"]
password = secrets.token_urlsafe(40)
role = "oil_kafka_ingest"
install = "test ! -e /etc/kafka-demo/oil-gp-ingest-password || exit 10; t=$(mktemp); trap 'rm -f $t' EXIT; cat > $t; sudo install -o kafka -g kafka -m 600 $t /etc/kafka-demo/oil-gp-ingest-password"
r = subprocess.run(
    vm + [install], input=password, text=True, capture_output=True, timeout=45
)
if r.returncode:
    raise SystemExit("credential setup failed or already exists; no GP changes")
encoded = "md5" + hashlib.md5((password + role).encode()).hexdigest()
sql = f"""BEGIN;
CREATE ROLE {role} LOGIN ENCRYPTED PASSWORD '{encoded}';
GRANT CONNECT ON DATABASE og_dwh TO {role};
GRANT USAGE ON SCHEMA oil_stg TO {role};
GRANT SELECT, UPDATE ON oil_stg.kafka_checkpoint TO {role};
GRANT INSERT ON oil_stg.event_log TO {role};
GRANT SELECT, INSERT, UPDATE ON oil_stg.batch_control TO {role};
-- GP 6 requires UPDATE for nextval; SELECT permits safe inspection of sequence state.
GRANT USAGE, SELECT, UPDATE ON SEQUENCE oil_stg.kafka_batch_id_seq TO {role};
INSERT INTO oil_stg.kafka_checkpoint(topic,kafka_partition,next_offset) VALUES ('oil.events.v1',0,0),('oil.events.v1',1,0),('oil.events.v1',2,0);
COMMIT;"""
command = "sudo -u gpadmin -H bash -c 'cd /home/gpadmin; source .gp-demo-env; psql -X -qAt -v ON_ERROR_STOP=1 -d og_dwh'"
r = subprocess.run(
    gp + [command], input=sql, text=True, capture_output=True, timeout=60
)
if r.returncode:
    print("ROLE_OR_CHECKPOINT_TRANSACTION_FAILED; inspect GP state before retry")
    raise SystemExit(1)
print("OIL_GP_ROLE_AND_VERIFIED_EMPTY_TOPIC_CHECKPOINTS_READY")
