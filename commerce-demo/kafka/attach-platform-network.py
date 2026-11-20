#!/usr/bin/env python3
"""Attach a dedicated platform port to Kafka VM; resumable, no secrets."""
import json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'vk-data-migration-2026-11-15/runbooks'))
from cloud_api import Cloud
c=Cloud();assert c.project=='a784cccc62434c279df4ecc1258b2674'
p=Path(__file__).with_name('cloud-resources.json');s=json.loads(p.read_text())
def save():p.write_text(json.dumps(s,indent=2)+'\n')
network='08fdaa72-d775-45c6-9a8e-44a98d713089';subnet='27c60550-99bb-49c3-9af5-52e134dc51ac';server=s['server']['id']
net=c.call('network','/v2.0/networks/'+network)['network']
assert net['shared'] and net['status']=='ACTIVE' and 'MS1' in net['sdn_presence_zones']
if 'platform_sg' not in s:
 x=c.call('network','/v2.0/security-groups','POST',{'security_group':{'name':'webinar-kafka-to-dp','description':'Dedicated platform interface, restricted egress'}})['security_group'];s['platform_sg']={'id':x['id']};save()
sg=s['platform_sg']['id']; detail=c.call('network','/v2.0/security-groups/'+sg)['security_group']
for rule in detail['security_group_rules']:
 if rule['direction']=='egress' and rule.get('remote_ip_prefix') is None:
  c.call('network','/v2.0/security-group-rules/'+rule['id'],'DELETE')
for proto,port,ip in [('tcp',443,'10.0.2.16/32'),('tcp',443,'10.0.2.242/32'),('udp',53,'10.0.2.3/32'),('tcp',53,'10.0.2.3/32')]:
 key=f'platform_egress_{proto}_{port}_{ip.split(".")[-1].split("/")[0]}'
 if key not in s:
  rule={'security_group_id':sg,'direction':'egress','ethertype':'IPv4','protocol':proto,'port_range_min':port,'port_range_max':port,'remote_ip_prefix':ip}
  x=c.call('network','/v2.0/security-group-rules','POST',{'security_group_rule':rule})['security_group_rule'];s[key]=x['id'];save()
if 'platform_port' not in s:
 x=c.call('network','/v2.0/ports','POST',{'port':{'name':'webinar-kafka-platform-port','network_id':network,'fixed_ips':[{'subnet_id':subnet}],'security_groups':[sg]}})['port'];s['platform_port']={k:x[k] for k in ('id','mac_address','fixed_ips')};save();print('PORT',s['platform_port'],flush=True)
port=s['platform_port']['id'];x=c.call('network','/v2.0/ports/'+port)['port']
if x.get('device_id') and x['device_id']!=server:raise RuntimeError('port attached to unexpected device')
if not x.get('device_id'):
 c.call('compute','/servers/'+server+'/os-interface','POST',{'interfaceAttachment':{'port_id':port}});print('ATTACHED',port,flush=True)
s['platform_attached']=True;save()
