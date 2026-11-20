# Kafka Connect и LakeKeeper: результат подготовки

Дата проверки: 20 ноября 2026. Финальная миграция бизнес-данных, бизнесовый Iceberg sink и переключение BI не запускались.

## Подтверждено

- Создана отдельная VM `webinar-kafka-demo` в проекте Greenplum. Kafka и Connect 3.9.1 работают; сеть dp-103 присоединена отдельным интерфейсом VM, основной маршрут и GP connector сохранены. Broker использует mTLS; Connect REST доступен только с localhost.
- `webinar-commerce-gp-ingest` и его task `RUNNING`. Kafka Connect → Greenplum проверен ранее на отдельной временной схеме и двух событиях с перезапуском коннектора; тестовые данные удалены. Генератор бизнес-событий не запускался.
- Создан отдельный CIAM client `webinar-iceberg-b33bfcb7f5db` с LakeKeeper principal `oidc~webinar-iceberg-b33bfcb7f5db`. Секрет хранится на Kafka VM в `/etc/kafka-demo/iceberg-client-credential`, владелец kafka, права 0600. После удаления тестовых grants у principal нет effective project/warehouse actions; бизнес-права ему не выдавались.
- Штатный OAuth2Manager Iceberg 1.9.2 получил первый token, но не смог обновить его при 20-секундном TTL; запрос token-exchange к CIAM вернул 400. Для совместимости создан отдельный **кастомный** pluggable AuthManager: он по запросу переиздаёт client_credentials через HTTPS, использует файл секрета и ограничивает адрес LakeKeeper. Java harness с временной учётной записью и TTL 20 секунд подтвердил смену token при последующем запросе; доступ к чужому хосту отклонён. Это не фоновой refresh, а проверенное обновление при обращении.
- JAR `webinar-ciam-auth-1.jar`, SHA-256 `890211b340755040f66bad00fdce60f20d62d7999eb93f5b6d09f1d1c4466219`, находится в каталоге плагина Iceberg на Kafka VM. Исходный код — `iceberg-auth-src/demo/iceberg/CiamAuthManager.java`. Проверен отдельный Java truststore с публичными CA платформы; системная проверка TLS не отключалась.
- Выполнен технический smoke через отдельный worker/topic, изолированный namespace и scoped grants: Kafka Connect Iceberg Sink → LakeKeeper → S3 remote signing. Snapshot показал `added-records=1`; независимое чтение через Iceberg Java с проверкой TLS подтвердило `PROBE_READ_COUNT=1` и `PROBE_VALUE_MATCH=true`. Для readback harness временно использовался Hadoop mapreduce jar 3.4.1; в worker он не устанавливался. Начальные commit циклы истекали по timeout; причина задержки не определена, позже snapshot успешно записан.

## Очистка

Test connector, worker/unit, пять технических Kafka topics и временные секреты удалены; admin port-forward остановлен. Администратор удалил test table с purge, namespace и точечно выданные grants; оба объекта ответили 404, effective project/warehouse actions постоянного principal пусты. S3 ListObjectsV2 по test prefix вернул 0 объектов и `IsTruncated=false`. Постоянная отдельная identity и её защищённый credential оставлены для будущей работы; исходный GP connector и task `RUNNING`.

## До бизнес-миграции

`iceberg-business-sink.template.json` — **только файл**, предполагает PAUSED и отключённое создание таблиц; экземпляр не зарегистрирован. `smt-src/demo/iceberg/EnvelopeToStaging.java` скомпилирован, но не установлен и не испытан на business envelope. В его варианте batch_id детерминирован отдельно для каждой записи и не совпадает с Greenplum, received_at остаётся NULL, а batch_control не формируется. Нужны решение по оркестрации и идемпотентности, согласованные offsets и граница, validation типов, replay/delete и scoped права на реально созданные бизнес-объекты. См. `business-sink-contract.md` и `iceberg-sink-readiness.md`.

Демонстрационный Kafka single node не является HA и использует replication factor 1. Необходимы эксплуатационные доработки: наблюдаемость, ротация client secret и CA, аварийное восстановление, подтверждённая обработка повторов и корректировок, нагрузочный тест. Состояние `RUNNING` не является доказательством своевременной обработки данных.
