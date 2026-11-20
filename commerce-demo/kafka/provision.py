#!/usr/bin/env python3
"""Create dedicated Kafka demo VM; resumable, state contains no credentials."""
import json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'vk-data-migration-2026-11-15/runbooks'))
from cloud_api import Cloud
c=Cloud(); assert c.project=='a784cccc62434c279df4ecc1258b2674'
p=Path(__file__).with_name('cloud-resources.json')
s=json.loads(p.read_text()) if p.exists() else {'project':c.project}
def save():p.write_text(json.dumps(s,indent=2)+'\n')
def create(key,service,path,body,result):
 if key not in s:
  x=c.call(service,path,'POST',body)[result];s[key]={'id':x['id'],'name':x.get('name')};save();print(key,s[key],flush=True)
 return s[key]['id']
sg=create('security_group','network','/v2.0/security-groups',{'security_group':{'name':'webinar-kafka-demo','description':'Private Kafka demo, SSH and TLS from GP security group only'}},'security_group')
gp_sg='6466af68-4684-4408-8b1e-7af447f109a7'
for port in (22,9093):
 key='ingress_'+str(port)
 if key not in s:
  x=c.call('network','/v2.0/security-group-rules','POST',{'security_group_rule':{'security_group_id':sg,'direction':'ingress','ethertype':'IPv4','protocol':'tcp','port_range_min':port,'port_range_max':port,'remote_group_id':gp_sg}})['security_group_rule'];s[key]=x['id'];save()
network='f0c3632a-8fcb-4b40-92cd-3a060f78ea24'
subnet='77ba084d-57f6-42d2-b909-eb0ccb55c020'
port=create('port','network','/v2.0/ports',{'port':{'name':'webinar-kafka-demo-port','network_id':network,'fixed_ips':[{'subnet_id':subnet,'ip_address':'10.77.25.20'}],'security_groups':[sg]}},'port')
create('server','compute','/servers',{'server':{'name':'webinar-kafka-demo','flavorRef':'b95087f9-3a2f-4414-b068-7a01f982f960','key_name':'vk-migration-demo-20261115','availability_zone':'MS1','networks':[{'port':port}],'metadata':{'purpose':'gp-lakehouse-webinar-demo','owner':'n.surovegin'},'block_device_mapping_v2':[{'source_type':'image','destination_type':'volume','uuid':'d3db2dca-e0df-45f8-980d-f535d2513df6','volume_size':80,'volume_type':'ceph-ssd','boot_index':0,'delete_on_termination':False}] }},'server')
