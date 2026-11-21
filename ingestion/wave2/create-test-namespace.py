#!/usr/bin/env python3
"""Platform pod only: create test namespace and grant only create/modify there."""
import json,urllib.request,urllib.error,urllib.parse
opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
def req(path,body=None,token=None,method=None):
 h={}
 if token:h['Authorization']='Bearer '+token
 if body is not None:h['Content-Type']='application/json';body=json.dumps(body).encode()
 try:
  with opener.open(urllib.request.Request('http://lakekeeper-service:8181'+path,data=body,headers=h,method=method),timeout=15) as r:
   raw=r.read();return r.status,json.loads(raw) if raw else {}
 except urllib.error.HTTPError as e:return e.code,{}
with opener.open(urllib.request.Request('http://127.0.0.1:8080/token',data=b'grant_type=client_credentials',headers={'Content-Type':'application/x-www-form-urlencoded'}),timeout=10) as r:token=json.load(r)['access_token']
wid='be4599ce-dbba-11f1-a520-7382628b06be';name='oil_ingest_probe_20261122';base='/catalog/v1/'+wid+'/namespaces';p='oidc~webinar-iceberg-b33bfcb7f5db'
st,_=req(base+'/'+name,token=token)
if st!=404:raise RuntimeError('test namespace not absent; no mutation')
st,_=req(base,{'namespace':[name]},token)
if st not in (200,201):raise RuntimeError('namespace creation HTTP '+str(st))
st,d=req(base+'/'+name,token=token)
if st!=200:raise RuntimeError('created namespace not readable')
nid=d['properties']['namespace_id'];print('TEST_NAMESPACE',name,'UUID',nid,flush=True)
perm='/management/v1/permissions/namespace/'+nid
st,d=req(perm+'/assignments',token=token)
if st!=200 or any(p in json.dumps(x) for x in d.get('assignments',[])):raise RuntimeError('unexpected namespace assignments')
st,_=req(perm+'/assignments',{'writes':[{'user':p,'type':'create'},{'user':p,'type':'modify'}],'deletes':[]},token)
print('TEST_NAMESPACE_GRANT_HTTP',st,flush=True)
if st not in (200,204):raise RuntimeError('grant failed; namespace requires cleanup')
