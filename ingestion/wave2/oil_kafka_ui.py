#!/usr/bin/env python3
"""Loopback-only fixed read-only demo dashboard; no writes or secret output."""
import json
import os
import socket
import urllib.request
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from confluent_kafka import Consumer, TopicPartition

HOST='127.0.0.1'; PORT=18086
CUT={0:5170,1:5196,2:5159}

def connect_get(port, path):
    try:
        request=urllib.request.Request('http://127.0.0.1:%d%s' % (port,path))
        with urllib.request.urlopen(request,timeout=4) as r: return json.load(r)
    except Exception: return None

def state():
    cfg={'bootstrap.servers':'10.77.25.20:9093','security.protocol':'SSL',
         'ssl.ca.location':'/etc/oil-kafka-ui/ca.crt','ssl.certificate.location':'/etc/oil-kafka-ui/client.crt',
         'ssl.key.location':'/etc/oil-kafka-ui/client.key','group.id':'oil-ui-metadata-only',
         'enable.auto.commit':False,'enable.auto.offset.store':False}
    c=Consumer(cfg)
    try:
        m=c.list_topics(timeout=8); t=m.topics.get('oil.events.v1')
        if not t or t.error: raise RuntimeError('topic unavailable')
        rows=[]
        for p in sorted(t.partitions):
            lo,hi=c.get_watermark_offsets(TopicPartition('oil.events.v1',p),timeout=5,cached=False)
            rows.append({'partition':p,'low':lo,'high':hi,'cut':CUT.get(p)})
        broker={'ok':True,'cluster_id':getattr(m,'cluster_id',None),'partitions':rows}
    except Exception: broker={'ok':False,'partitions':[]}
    finally:c.close()
    a=connect_get(18084,'/connectors/webinar-oil-gp-ingest/status')
    b=connect_get(18085,'/connectors/webinar-oil-wave2-iceberg/status')
    off=connect_get(18085,'/connectors/webinar-oil-wave2-iceberg/offsets')
    return {'observed_at_utc':datetime.now(timezone.utc).isoformat(),'broker':broker,
            'source':a,'wave2':b,'wave2_offsets':off,
            'notice':'Connect offsets — не доказательство целостного GP-среза; потребление второй волны приостановлено, исторические простои ещё не перенесены.'}

PAGE='''<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Oil migration · Kafka</title><style>
:root{font-family:-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif;color:#17233c;background:#f3f6fc}*{box-sizing:border-box}body{margin:0}main{max-width:1120px;margin:auto;padding:42px 28px}header{display:flex;justify-content:space-between;align-items:end;gap:20px}h1{font-size:32px;margin:5px 0 10px;letter-spacing:-.7px}h2{font-size:18px;margin:0 0 18px}p{color:#62708a;line-height:1.5}.eyebrow{color:#1465e8;font-weight:700;font-size:12px;letter-spacing:1.3px;text-transform:uppercase}.time{font-size:13px;color:#687894}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin:28px 0}.card{background:white;border:1px solid #e3eaf5;border-radius:18px;padding:23px;box-shadow:0 6px 20px #173b6810}.label{font-size:13px;color:#72809a}.value{font-size:25px;font-weight:750;margin-top:12px}.badge{display:inline-flex;padding:7px 12px;border-radius:30px;background:#edf3ff;color:#1e5bdb;font-size:13px;font-weight:700}.ok{background:#e4f7ee;color:#177b54}.warn{background:#fff3df;color:#aa6b05}.panel{display:grid;grid-template-columns:1.2fr 1fr;gap:16px}.row{display:flex;align-items:center;justify-content:space-between;padding:14px 0;border-bottom:1px solid #eef2f8;font-variant-numeric:tabular-nums}.row:last-child{border:0}.track{height:7px;background:#e9eff9;border-radius:20px;margin-top:8px;overflow:hidden}.bar{height:100%;background:#3a7cff;border-radius:20px}.foot{margin-top:20px;font-size:13px}.danger{padding:15px 18px;background:#fff8e8;border-radius:12px;color:#75531a;font-size:14px;line-height:1.5}@media(max-width:700px){header{display:block}.grid,.panel{grid-template-columns:1fr}main{padding:28px 18px}}</style></head><body><main><header><div><div class="eyebrow">VK Data Platform · demo</div><h1>Поток событий добычи</h1><p>Состояние Kafka и коннекторов для итеративной миграции</p></div><div class="time" id="updated">Ожидание данных</div></header><div class="grid"><div class="card"><div class="label">Источник</div><div class="value">oil.events.v1</div><p id="broker">Проверяем подключение</p></div><div class="card"><div class="label">Загрузка в Greenplum</div><div class="value" id="source">—</div><p>Отдельный source connector</p></div><div class="card"><div class="label">Поток во вторую волну</div><div class="value" id="wave2">—</div><p>Iceberg consumer</p></div></div><div class="panel"><section class="card"><h2>Позиции партиций</h2><div class="label">Начало удержания · текущая граница · cut первой волны</div><div id="partitions"></div></section><section class="card"><h2>Вторая волна</h2><div class="row"><span>Состояние</span><span class="badge" id="waveBadge">—</span></div><div class="row"><span>Задачи</span><strong id="tasks">—</strong></div><div class="row"><span>Целевая таблица</span><strong>event_log_wave2</strong></div><p class="foot">Consumer приостановлен; история простоев требует отдельной загрузки до зафиксированной границы.</p></section></div><p class="danger" id="notice">Метрики обновляются только для чтения. Статус коннектора и offsets не подтверждают корректность всей миграции.</p><p class="foot">Single-node Kafka · RF=1 · технический демостенд. Токены и данные событий в интерфейс не выводятся.</p></main><script>
const text=(id,v)=>document.getElementById(id).textContent=v;const status=x=>x&&x.connector?x.connector.state:'НЕДОСТУПЕН';async function refresh(){try{let r=await fetch('/api/state',{cache:'no-store'});if(!r.ok)throw Error();let d=await r.json();text('updated','Обновлено: '+new Date(d.observed_at_utc).toLocaleString('ru-RU'));text('source',status(d.source));text('wave2',status(d.wave2));text('waveBadge',status(d.wave2));text('tasks',d.wave2&&d.wave2.tasks?d.wave2.tasks.length:'—');text('broker',d.broker.ok?'Доступен · '+d.broker.partitions.length+' партиции':'Брокер недоступен');text('notice',d.notice);let root=document.getElementById('partitions');root.replaceChildren();for(let x of d.broker.partitions){let row=document.createElement('div');row.className='row';let left=document.createElement('span');left.textContent='Партиция '+x.partition;let right=document.createElement('strong');right.textContent=x.low+' · '+x.high+' · '+(x.cut??'—');row.append(left,right);root.append(row)}}catch(e){text('updated','Нет связи с локальным сервисом')}}refresh();setInterval(refresh,10000);
</script></body></html>'''

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def do_GET(self):
        host=self.headers.get('Host','')
        origin=self.headers.get('Origin')
        if host not in ('127.0.0.1:18086','localhost:18086') or (origin and origin not in ('http://127.0.0.1:18086','http://localhost:18086')):
            self.send_error(403);return
        if self.path=='/': data=PAGE.encode(); kind='text/html; charset=utf-8'
        elif self.path=='/api/state': data=json.dumps(state(),ensure_ascii=False).encode(); kind='application/json; charset=utf-8'
        else:self.send_error(404);return
        self.send_response(200);self.send_header('Content-Type',kind);self.send_header('Content-Length',str(len(data)))
        self.send_header('Cache-Control','no-store');self.send_header('X-Content-Type-Options','nosniff')
        self.send_header('Content-Security-Policy',"default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'")
        self.end_headers();self.wfile.write(data)

if __name__=='__main__':ThreadingHTTPServer((HOST,PORT),Handler).serve_forever()
