# Сервисы стенда

Доступ к адресам 10.0.2.x требует маршрута в сеть стенда/VPN. HTTPS требует доверенного CA платформы.

| Сервис | Адрес | Подтверждённая версия / назначение |
|---|---|---|
| Portal | https://dp-103.mcs.local/app/ | Data Platform |
| CIAM | https://dp-103.mcs.local/iam-admin/ | Flow v26.1.0, роли пользователей |
| Greenplum | 160.5.219.123:5432, og_dwh | 6.26.2 / PostgreSQL 9.4.26 |
| Kafka / Connect | Kafka VM 10.77.25.20 | 3.9.0, topic oil.events.v1, 3 partitions |
| Kafka наблюдение | http://127.0.0.1:18086/ | Собственная read-only панель через SSH tunnel |
| Airflow | http://10.0.2.13:8080 | 3.1.8, oil_gp_release / oil_wave2_release |
| CedrusData Engine | https://10.0.2.17 | SQL version 476-3; SQL endpoints .18/.19 |
| LakeKeeper | https://10.0.2.13 | 0.11.2; API https://10.0.2.16 |
| Data Catalog | http://10.0.2.11:8585 | 2.0.0 |
| Superset | https://10.0.2.24 | 6.1.0 |
| JupyterHub | https://10.0.2.26 | Hub 5.2.1, дополнительная диагностика |
| Spark | https://10.0.2.12 | 3.5.1 / Scala 2.12.18 / JVM 17.0.17; альтернативный путь |

## Отчёты

- [GP: добыча](https://10.0.2.24/superset/dashboard/3/) — dataset 4, source DB 3.
- [GP: эффективность и простои](https://10.0.2.24/superset/dashboard/4/) — dataset 5.
- [DLH: первая перенесённая цепочка](https://10.0.2.24/superset/dashboard/5/) — dataset 6, DB 2, oil_mart.agg_field_day.
- [DLH: подготовленная вторая цепочка](https://10.0.2.24/superset/dashboard/6/) — dataset 8, charts 19–22; до вебинара пустой oil_demo_template.field_performance.
