# Компилирует текущий OilEnvelopeToStaging, выполняет JVM-проверку сохранения JSON/координат и обязательного времени приёма, затем заменяет ровно один установленный класс. Старый JAR сохраняется за пределами plugin.path. Перезапускается тольк.
"""Compile, test and update the installed staging SMT without changing GP ingestion."""
import json,subprocess
from pathlib import Path
ROOT=next(p/'platform-bridge' for p in Path(__file__).resolve().parents if (p/'platform-bridge/bridge').is_dir())


def main():
    """Validate the real JVM mapping before replacing its single class and restarting target Connect."""
    source=(ROOT.parent/'webinar-delivery-2026-11-20/dwh-greenplum-scripts/connectors/iceberg/transform/src/demo/oil/OilEnvelopeToStaging/OilEnvelopeToStaging.java').read_text()
    program='source='+repr(source)+r"""
import json,subprocess,tempfile,shutil
from pathlib import Path
from zipfile import ZipFile

def run(args):
    "Run a fixed compiler/service command; credentials are not arguments."
    result=subprocess.run(args,text=True,capture_output=True,timeout=90)
    if result.returncode:raise RuntimeError(result.stderr[-1500:])
    return result.stdout
found=[]
for path in Path('/opt/kafka-demo/plugins/iceberg').glob('*.jar'):
 with ZipFile(path) as archive:
  if 'demo/oil/OilEnvelopeToStaging.class' in archive.namelist():found.append(path)
if len(found)!=1:raise RuntimeError('Installed staging class must have one unambiguous JAR')
jar=found[0];java='/opt/kafka-demo/jdk/bin/'
classpath='/opt/kafka-demo/current/libs/*:/opt/kafka-demo/plugins/iceberg/*'
with tempfile.TemporaryDirectory(prefix='staging-build-') as directory:
 base=Path(directory);(base/'OilEnvelopeToStaging.java').write_text(source)
 run([java+'javac','--release','11','-cp',classpath,'-d',str(base),str(base/'OilEnvelopeToStaging.java')])
 harness=r'''import java.util.*;import org.apache.kafka.connect.sink.SinkRecord;import org.apache.kafka.connect.data.*;
public class StagingContractCheck {
 public static void main(String[] args) {
  demo.oil.OilEnvelopeToStaging t=new demo.oil.OilEnvelopeToStaging();
  t.configure(Collections.singletonMap("allowed.topic","bridge-contract-check"));
  String document="{\"schema_version\":1,\"event_id\":\"check-1\",\"event_type\":\"field\",\"entity_id\":\"F001\",\"entity_version\":1,\"op\":\"U\",\"event_time\":\"2026-01-01T00:00:00Z\",\"payload\":{\"field_id\":\"F001\"}}";
  long before=System.currentTimeMillis();
  SinkRecord input=new SinkRecord("bridge-contract-check",2,null,"field:F001",Schema.STRING_SCHEMA,document,10L);
  Struct value=(Struct)t.apply(input).value();
  if (!(value.get("received_at") instanceof java.util.Date))throw new AssertionError("missing receipt time");
  long receipt=((java.util.Date)value.get("received_at")).getTime();
  if (receipt<before || receipt>System.currentTimeMillis())throw new AssertionError("not an actual receipt clock");
  if (!document.equals(value.get("event_json")))throw new AssertionError("JSON changed");
  if (!Long.valueOf((2L<<56)|10L).equals(value.get("batch_id")))throw new AssertionError("delivery identity changed");
  if (value.schema().field("received_at").schema().isOptional())throw new AssertionError("receipt must be required");
  System.out.println("STAGING_CONTRACT_PASS");
 }
}'''
 (base/'StagingContractCheck.java').write_text(harness)
 run([java+'javac','--release','11','-cp',str(base)+':'+classpath,'-d',str(base),str(base/'StagingContractCheck.java')])
 assert 'STAGING_CONTRACT_PASS' in run([java+'java','-cp',str(base)+':'+classpath,'StagingContractCheck'])
 backup=Path('/var/lib/platform-bridge/backups');backup.mkdir(parents=True,exist_ok=True)
 saved=backup/'staging-before-received-at.jar'
 if not saved.exists():shutil.copy2(jar,saved)
 run([java+'jar','uf',str(jar),'-C',str(base),'demo/oil/OilEnvelopeToStaging.class'])
 run(['systemctl','restart','webinar-oil-wave2-connect.service'])
print(json.dumps({'staging_jvm_contract':'PASS','required_received_at':True,'source_gp_worker_restarted':False,'jar':str(jar)}))
"""
    command=['ssh','-F',str(ROOT.parent/'vk-data-migration-2026-11-15/runbooks/gp-ssh.conf'),'-J','gp-demo-coordinator','-i',str(Path.home()/'.ssh/vk_migration_demo_20261115_rsa'),'ubuntu@10.77.25.20','sudo python3 -']
    result=subprocess.run(command,input=program,text=True,capture_output=True,timeout=150)
    if result.returncode:raise RuntimeError('Staging build failed: '+result.stderr[-1800:])
    print(result.stdout)
    (ROOT/'var/online-upgrade/staging-contract.json').write_text(result.stdout)


if __name__=='__main__':main()
