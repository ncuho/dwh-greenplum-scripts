#!/usr/bin/env python3
"""Provision dedicated GP staging writer and initial offsets for an empty topic."""
import hashlib,os,secrets,subprocess
from pathlib import Path
base=Path(__file__).resolve().parent; conf=base.parent/'vk-data-migration-2026-11-15/runbooks/gp-ssh.conf'
ssh=['ssh','-F',str(conf),'gp-demo-coordinator']
secret_dir=Path.home()/'.local/state/webinar-kafka-demo'; secret_dir.mkdir(mode=0o700,parents=True,exist_ok=True)
secret=secret_dir/'gp-ingest-password';fd=os.open(secret,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
password=secrets.token_urlsafe(32)
with os.fdopen(fd,'w') as f:f.write(password+'\n')
hashpass='md5'+hashlib.md5((password+'kafka_demo_ingest').encode()).hexdigest()
sql=f'''BEGIN;
CREATE ROLE kafka_demo_ingest LOGIN ENCRYPTED PASSWORD '{hashpass}';
GRANT CONNECT ON DATABASE og_dwh TO kafka_demo_ingest;
GRANT USAGE ON SCHEMA demo_stg TO kafka_demo_ingest;
GRANT SELECT, UPDATE ON demo_stg.kafka_checkpoint TO kafka_demo_ingest;
GRANT INSERT ON demo_stg.kafka_event TO kafka_demo_ingest;
GRANT INSERT, UPDATE ON demo_stg.batch_control TO kafka_demo_ingest;
GRANT USAGE ON SEQUENCE demo_stg.kafka_batch_id_seq TO kafka_demo_ingest;
INSERT INTO demo_stg.kafka_checkpoint(topic,kafka_partition,next_offset) VALUES ('commerce.events.v1',0,0),('commerce.events.v1',1,0),('commerce.events.v1',2,0);
COMMIT;'''
cmd="sudo -u gpadmin -H bash -c 'cd /home/gpadmin; source .gp-demo-env; psql -X -qAt -v ON_ERROR_STOP=1 -d og_dwh'"
r=subprocess.run(ssh+[cmd],input=sql,text=True,capture_output=True)
if r.returncode:raise SystemExit('GP role setup failed: '+r.stderr[-1000:])
target=['ssh','-F',str(conf),'-o','ProxyJump=gp-demo-coordinator','-i',str(Path.home()/'.ssh/vk_migration_demo_20261115_rsa'),'ubuntu@10.77.25.20']
r=subprocess.run(target+['umask 077; cat > /tmp/kafka-ingest-password; sudo install -o kafka -g kafka -m 600 /tmp/kafka-ingest-password /etc/kafka-demo/gp-ingest-password; rm -f /tmp/kafka-ingest-password'],input=password,text=True,capture_output=True)
if r.returncode:raise SystemExit('Credential upload failed; GP role persists; password retained in protected local file')
print('GP_INGEST_ROLE_AND_OFFSETS_PREPARED')
