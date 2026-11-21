#!/usr/bin/env python3
"""Delete only verified temporary namespace/table and its two direct grants."""
import json,urllib.request,urllib.error,urllib.parse
op=urllib.request.build_opener(urllib.request.ProxyHandler({}))
def req(path,body=None,token=None,method=None):
 h={}
 if token:h['Authorization']='Bearer '+token
 if body is not None:h['Content-Type']='application/json';body=json.dumps(body).encode()
 try:
  with op.open(urllib.request.Request('http://lakekeeper-service:8181'+path,data=body,headers=h,method=method),timeout=20) as r:
   raw=r.read();return r.status,json.loads(raw) if raw else {}
 except urllib.error.HTTPError as e:return e.code,{}
with op.open(urllib.request.Request('http://127.0.0.1:8080/token',data=b'grant_type=client_credentials',headers={'Content-Type':'application/x-www-form-urlencoded'}),timeout=10) as r:t=json.load(r)['access_token']
w='be4599ce-dbba-11f1-a520-7382628b06be';n='oil_ingest_probe_20261122';nid='01a1ffff-8820-7e10-9fbc-566f9e944056';tid='01a20001-2e24-78a1-b73c-30fe76a24031';p='oidc~webinar-iceberg-b33bfcb7f5db';root='/catalog/v1/'+w+'/namespaces/'+n
st,d=req(root,token=t)
if st!=200 or d.get('properties',{}).get('namespace_id')!=nid:raise RuntimeError('test namespace identity mismatch')
st,d=req(root+'/tables',token=t); names=[x['name'] for x in d.get('identifiers',[])]
if st!=200 or names!=['event_log']:raise RuntimeError('unexpected table list; no deletion')
st,d=req(root+'/tables/event_log',token=t)
if st!=200 or d.get('metadata',{}).get('table-uuid')!=tid:raise RuntimeError('test table identity mismatch')
st,_=req(root+'/tables/event_log?purgeRequested=true',token=t,method='DELETE');print('TEST_TABLE_DELETE_HTTP',st)
if st not in (200,204):raise RuntimeError('test table cleanup failed')
st,_=req(root+'/tables/event_log',token=t);print('TEST_TABLE_ABSENT_HTTP',st)
if st!=404:raise RuntimeError('test table persists')
perm='/management/v1/permissions/namespace/'+nid
st,_=req(perm+'/assignments',{'writes':[],'deletes':[{'user':p,'type':'create'},{'user':p,'type':'modify'}]},t);print('TEST_GRANTS_DELETE_HTTP',st)
if st not in (200,204):raise RuntimeError('test grants cleanup failed')
st,_=req(root,token=t,method='DELETE');print('TEST_NAMESPACE_DELETE_HTTP',st)
if st not in (200,204):raise RuntimeError('test namespace cleanup failed')
st,_=req(root,token=t);print('TEST_NAMESPACE_ABSENT_HTTP',st)
if st!=404:raise RuntimeError('test namespace persists')
