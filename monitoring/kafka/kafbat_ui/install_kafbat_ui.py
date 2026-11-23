"""Install the pinned official Kafbat UI on the existing Kafka VM.

The UI uses its own read-only mTLS principal and listens on loopback only.
No credentials are printed or written to this repository. Existing Kafka,
Connect workers, the producer and the small legacy observer keep running.
"""
import json
import os
import subprocess
from pathlib import Path

REMOTE = r"""
import hashlib,json,os,pwd,grp,shutil,subprocess,urllib.request
from pathlib import Path

def command(args):
    "Run a fixed installation command without publishing credentials."
    result=subprocess.run(args,capture_output=True,text=True,timeout=90)
    if result.returncode:raise RuntimeError('Installation command failed: '+args[0])
    return result.stdout

name='oil-kafbat-ui'
try:account=pwd.getpwnam(name)
except KeyError:
    command(['useradd','--system','--home','/opt/oil-kafbat-ui','--shell','/usr/sbin/nologin',name])
    account=pwd.getpwnam(name)
root=Path('/opt/oil-kafbat-ui');root.mkdir(mode=0o755,exist_ok=True)
config=Path('/etc/oil-kafbat-ui');config.mkdir(mode=0o750,exist_ok=True)
os.chown(config,0,account.pw_gid)
jar=root/'api-v1.5.1.jar'
digest='c0b689f801423b66b0ff50993a2d6b32fe3616a1a3074046c97110c5e8b0cfd9'
if not jar.exists() or hashlib.sha256(jar.read_bytes()).hexdigest()!=digest:
    temp=jar.with_suffix('.download')
    with urllib.request.urlopen('https://github.com/kafbat/kafka-ui/releases/download/v1.5.1/api-v1.5.1.jar',timeout=60) as response,temp.open('wb') as out:
        shutil.copyfileobj(response,out)
    if hashlib.sha256(temp.read_bytes()).hexdigest()!=digest:raise RuntimeError('Official release SHA256 mismatch')
    temp.replace(jar);jar.chmod(0o644)
# Kafbat 1.5.1 requires Java 25. Keep Kafka's Java 17 unchanged.
if not (root/'jdk25/bin/java').exists():
    import tarfile
    archive=root/'jdk25.tar.gz'
    url='https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.5.1%2B2/OpenJDK25U-jdk_x64_linux_hotspot_25.0.5.1_2.tar.gz'
    expected='760f91b22c3efc9bd1b64ff950598231be82928cc807e30691a0e7a2995a62c0'
    if not archive.exists() or hashlib.sha256(archive.read_bytes()).hexdigest()!=expected:
        with urllib.request.urlopen(url,timeout=90) as response,archive.open('wb') as output:
            shutil.copyfileobj(response,output)
    if hashlib.sha256(archive.read_bytes()).hexdigest()!=expected:raise RuntimeError('JDK release checksum mismatch')
    destination=root/'jdk25-extract';destination.mkdir(exist_ok=True)
    with tarfile.open(archive) as package:
        for member in package.getmembers():
            if member.name.startswith('/') or '..' in Path(member.name).parts:raise RuntimeError('Unsafe JDK archive')
        package.extractall(destination)
    next(destination.iterdir()).rename(root/'jdk25');destination.rmdir();archive.unlink()
if not (config/'client.pem').exists():
    command(['openssl','req','-newkey','rsa:2048','-nodes','-keyout',str(config/'client.key'),'-out',str(config/'client.csr'),'-subj','/CN=oil-kafbat-ui'])
    (config/'client.ext').write_text('extendedKeyUsage=clientAuth\n')
    command(['openssl','x509','-req','-in',str(config/'client.csr'),'-CA','/etc/kafka-demo/ca.crt','-CAkey','/etc/kafka-demo/ca.key','-CAcreateserial','-out',str(config/'client.crt'),'-days','365','-extfile',str(config/'client.ext')])
    (config/'client.pem').write_bytes((config/'client.key').read_bytes()+(config/'client.crt').read_bytes())
shutil.copyfile('/etc/kafka-demo/ca.crt',config/'ca.crt')
for path in config.iterdir():
    os.chown(path,0,account.pw_gid);path.chmod(0o640)
acl=['sudo','-u','kafka','env','JAVA_HOME=/opt/kafka-demo/jdk','/opt/kafka-demo/current/bin/kafka-acls.sh','--bootstrap-server','10.77.25.20:9093','--command-config','/etc/kafka-demo/client.properties','--add','--allow-principal','User:CN=oil-kafbat-ui']
# A wildcard UI ACL makes Kafka's previous no-ACL fallback deny other clients.
# Declare existing worker capabilities first, including their internal logs and
# consumer groups, so enabling observability cannot stop Connect ingestion.
base=acl[:acl.index('--allow-principal')]
for principal,prefix in [('oil-connect-worker','webinar-oil-connect-'),('oil-iceberg-wave2-worker','webinar-oil-wave2-connect-')]:
    identity=base+['--allow-principal','User:CN='+principal]
    command(identity+['--operation','All','--topic',prefix,'--resource-pattern-type','prefixed'])
    for group in ['webinar-oil','connect-','bridge-']:
        command(identity+['--operation','Read','--group',group,'--resource-pattern-type','prefixed'])
    command(identity+['--operation','Describe','--cluster'])
target=base+['--allow-principal','User:CN=oil-iceberg-wave2-worker']
for prefix in ['bridge-','manual-oil-','webinar-oil-wave2-iceberg-control']:
    command(target+['--operation','All','--topic',prefix,'--resource-pattern-type','prefixed'])
command(target+['--operation','Read','--group','manual-oil-','--resource-pattern-type','prefixed'])
command(base+['--allow-principal','User:CN=oil-producer','--operation','IdempotentWrite','--operation','Describe','--cluster'])
command(base+['--allow-principal','User:CN=oil-kafka-ui-metadata','--operation','Describe','--cluster'])
command(acl+['--operation','Read','--operation','Describe','--operation','DescribeConfigs','--topic','*'])
command(acl+['--operation','Describe','--group','*'])
command(acl+['--operation','Describe','--operation','DescribeConfigs','--cluster'])
configuration='''server:
  address: 127.0.0.1
  port: 18080
auth:
  type: DISABLED
dynamic:
  config:
    enabled: false
kafka:
  clusters:
    - name: Oil Production
      bootstrapServers: 10.77.25.20:9093
      readOnly: true
      properties:
        security.protocol: SSL
        ssl.truststore.type: PEM
        ssl.truststore.location: /etc/oil-kafbat-ui/ca.crt
        ssl.keystore.type: PEM
        ssl.keystore.location: /etc/oil-kafbat-ui/client.pem
        ssl.endpoint.identification.algorithm: https
      kafkaConnect:
        - name: Greenplum
          address: http://127.0.0.1:18084
        - name: Lakehouse
          address: http://127.0.0.1:18085
'''
(config/'application.yml').write_text(configuration)
os.chown(config/'application.yml',0,account.pw_gid);(config/'application.yml').chmod(0o640)
unit='''[Unit]
Description=Kafka observability with Kafbat UI
After=network-online.target webinar-kafka.service
[Service]
User=oil-kafbat-ui
Group=oil-kafbat-ui
ExecStart=/opt/oil-kafbat-ui/jdk25/bin/java -Xms128m -Xmx512m -Dspring.config.additional-location=file:/etc/oil-kafbat-ui/application.yml -jar /opt/oil-kafbat-ui/api-v1.5.1.jar
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
[Install]
WantedBy=multi-user.target
'''
Path('/etc/systemd/system/oil-kafbat-ui.service').write_text(unit)
command(['systemctl','daemon-reload']);command(['systemctl','enable','oil-kafbat-ui.service']);command(['systemctl','restart','oil-kafbat-ui.service'])
print(json.dumps({'service':'oil-kafbat-ui','version':'1.5.1','sha256':digest,'listen':'127.0.0.1:18080','read_only':True,'connect_workers':['Greenplum','Lakehouse']}))
"""


def main():
    """Deploy over the existing SSH path and save only non-secret evidence."""
    candidates=[Path(os.environ['BRIDGE_WORKSPACE'])] if os.environ.get('BRIDGE_WORKSPACE') else list(Path(__file__).resolve().parents)
    workspace=next((p for p in candidates if (p/'vk-data-migration-2026-11-15/runbooks/gp-ssh.conf').is_file()),None)
    if workspace is None:raise RuntimeError('Set BRIDGE_WORKSPACE to the configured workspace containing the SSH runbook')
    root=workspace/'platform-bridge'
    command=['ssh','-F',str(workspace/'vk-data-migration-2026-11-15/runbooks/gp-ssh.conf'),'-o','BatchMode=yes','-J','gp-demo-coordinator','-i',str(Path.home()/'.ssh/vk_migration_demo_20261115_rsa'),'ubuntu@10.77.25.20','sudo python3 -']
    result=subprocess.run(command,input=REMOTE,text=True,capture_output=True,timeout=600)
    if result.returncode:
        raise RuntimeError('Kafka UI installation failed: '+result.stderr[-600:])
    value=json.loads(result.stdout)
    destination=root/'var/online-upgrade/kafbat-install.json'
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps(value,indent=2))
    print(json.dumps(value))


if __name__=='__main__':main()
