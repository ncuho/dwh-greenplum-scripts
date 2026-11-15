#!/usr/bin/env python3
"""Record only actual 143-check evidence, without asserting a target cutover."""
import argparse,hashlib,json,os,subprocess
from pathlib import Path

def literal(v):return "'"+str(v).replace("'","''")+"'"
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('snapshot_dir',type=Path);p.add_argument('quality_jsonl',type=Path);a=p.parse_args()
 if not os.environ.get('PGSERVICE'):p.error('Set PGSERVICE')
 checks=[json.loads(l) for l in a.quality_jsonl.read_text().splitlines() if l.startswith('{')]
 if len(checks)!=143 or len({c['check'] for c in checks})!=143 or any(c['errors']!=0 for c in checks):p.error('143 unique passing checks required')
 m=json.loads((Path(__file__).resolve().parents[1]/'metadata/asset-manifest.json').read_text())
 sql=['BEGIN;','DELETE FROM ctl.quality_result WHERE batch_id=1;','DELETE FROM ctl.source_asset;','DELETE FROM ctl.publication_release WHERE release_id=1;']
 for asset in m['assets']:
  if asset['class']!='exact_existing_mirror':continue
  d=json.loads((a.snapshot_dir/(asset['name']+'.json')).read_text())
  if d['table']!=asset['name'] or d['columns']!=[c['name'] for c in asset['columns']]:p.error('Snapshot schema mismatch')
  digest=hashlib.sha256(json.dumps(asset['columns'],sort_keys=True).encode()).hexdigest()
  vals=[literal(asset['name']),literal(asset['source_fqn']),literal(d['snapshot_id']),str(len(d['rows'])),literal(digest),'current_timestamp']
  sql.append('INSERT INTO ctl.source_asset VALUES('+','.join(vals)+');')
 for i,c in enumerate(checks,1):sql.append('INSERT INTO ctl.quality_result VALUES('+','.join([str(i),'1',literal(c['check'].split(':')[-1]),literal(c['check']),'0',"'PASS'",'current_timestamp'])+');')
 sql.extend(["INSERT INTO ctl.publication_release VALUES(1,1,'VALIDATED_DEMO_NO_CUTOVER','positive_quality_checks:143;target:not_executed',current_timestamp,true);","UPDATE ctl.load_batch SET state='VALIDATED',finished_at=current_timestamp WHERE batch_id=1;",'COMMIT;'])
 r=subprocess.run(['psql','-X','-q','-v','ON_ERROR_STOP=1'],input='\n'.join(sql),text=True,capture_output=True)
 print('Validation metadata committed' if r.returncode==0 else 'Validation metadata failed; transaction rolled back');return r.returncode
if __name__=='__main__':raise SystemExit(main())
