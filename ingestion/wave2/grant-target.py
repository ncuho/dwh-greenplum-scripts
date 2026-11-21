#!/usr/bin/env python3
"""Run only inside platform m2m pod. Add exact grants; bearer remains in memory."""
import json,time,urllib.request,urllib.error,urllib.parse
opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
def req(path,body=None,token=None):
 h={}
 if token:h['Authorization']='Bearer '+token
 if body is not None:h['Content-Type']='application/json';body=json.dumps(body).encode()
 try:
  with opener.open(urllib.request.Request('http://lakekeeper-service:8181'+path,data=body,headers=h),timeout=15) as r:
   raw=r.read();return r.status,json.loads(raw) if raw else {}
 except urllib.error.HTTPError as e:return e.code,{}
with opener.open(urllib.request.Request('http://127.0.0.1:8080/token',data=b'grant_type=client_credentials',headers={'Content-Type':'application/x-www-form-urlencoded'}),timeout=10) as r:token=json.load(r)['access_token']
principal='oidc~webinar-iceberg-b33bfcb7f5db'
project='/management/v1/permissions/project/00000000-0000-0000-0000-000000000000'
table='/management/v1/permissions/warehouse/be4599ce-dbba-11f1-a520-7382628b06be/table/01a1fffc-dbc0-7b81-9eec-32462400ed4d'
other='/management/v1/permissions/warehouse/be4599ce-dbba-11f1-a520-7382628b06be/table/01a1ff99-4b7b-7080-beab-9eca1f0e6c61'
for base,relation in [(project,'describe'),(table,'modify')]:
 st,data=req(base+'/assignments',token=token)
 if st!=200:raise RuntimeError('cannot read assignments HTTP '+str(st))
 mine=[x for x in data.get('assignments',[]) if principal in json.dumps(x)]
 print('preexisting',base,'count',len(mine))
 if mine:raise RuntimeError('preexisting assignment requires review')
 st,_=req(base+'/assignments',{'writes':[{'user':principal,'type':relation}],'deletes':[]},token)
 print('grant',relation,'HTTP',st)
 if st not in (200,201,204):raise RuntimeError('grant failed')
time.sleep(2)
for label,base in [('project',project),('target_table',table),('wave1_table',other)]:
 st,data=req(base+'/access?principalUser='+urllib.parse.quote(principal),token=token)
 print('effective',label,'HTTP',st,'actions',data.get('allowed-actions'))
