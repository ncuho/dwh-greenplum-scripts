#!/usr/bin/env python3
"""Create only an empty distinct wave2 raw table; no source data migration."""
import json,subprocess,sys
from pathlib import Path
base=Path(__file__).resolve().parents[3]
source=(base/'vk-data-migration-2026-11-15/qa/mcp_readonly_probe.py').read_text().split("print(json.dumps({'initialize':")[0]
program='''
rpc('initialize',{'protocolVersion':'2024-11-05','capabilities':{},'clientInfo':{'name':'wave2-empty-target','version':'1'}},1)
rpc('notifications/initialized',{},None)
def query(sql,n):
 r=rpc('tools/call',{'name':'execute_query','arguments':{'query':sql}},n)
 d=r.get('result',{})
 if r.get('error') or d.get('isError'):raise RuntimeError('query failed: '+str(d.get('content',r.get('error')))[:400])
 return json.loads(d.get('structuredContent',{}).get('result','[]'))
a=query("SELECT count(*) AS n FROM dlh.information_schema.tables WHERE table_schema='oil_stg' AND table_name='event_log_wave2'",2)
if a[0]['n']:
 print(json.dumps({'status':'already_exists','no_change':True}));raise SystemExit(2)
query("CREATE TABLE dlh.oil_stg.event_log_wave2 WITH (format='PARQUET') AS SELECT * FROM dlh.oil_stg.event_log WHERE 1=0",3)
cols=query("SELECT column_name,data_type FROM dlh.information_schema.columns WHERE table_schema='oil_stg' AND table_name='event_log_wave2' ORDER BY ordinal_position",4)
count=query("SELECT count(*) AS n FROM dlh.oil_stg.event_log_wave2",5)
print(json.dumps({'status':'created','count':count[0]['n'],'columns':cols},ensure_ascii=False),flush=True)
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','redos@79.137.175.114','kubectl','exec','-i','-n','trinomcpcluster-xmrnjrpc','deploy/trino-mcp','--','python','-'],input=source+'\n'+program,text=True,capture_output=True,timeout=120)
if p.stdout:print(p.stdout,end='')
if p.returncode:
 print('Create incomplete; inspect table state before retry.',file=sys.stderr)
 print(p.stderr[-1200:],file=sys.stderr)
raise SystemExit(p.returncode)
