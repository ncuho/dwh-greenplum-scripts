# Kafka UI

Kafbat UI 1.5.1 наблюдает Kafka topics, partitions, messages, consumer groups и два Kafka Connect workers. Работает на существующей Kafka VM отдельным systemd service `oil-kafbat-ui.service`, на Java 25, с mTLS и read-only UI. Слушает только loopback 18080; рабочее место подключается SSH-туннелем на 18880.

Установщик фиксирует SHA-256 официальных JAR и JDK, задаёт права служебных identities до wildcard ACL UI и не меняет Java Kafka/Connect. Значения секретов не входят в Git. Скрипт запускается из рабочего пространства Platform Bridge, где доступны существующие SSH bindings. Старый observer 18086 остаётся для технического controller.

После установки: `systemctl status oil-kafbat-ui.service`, `curl http://127.0.0.1:18080/actuator/health`, затем Dashboard/Topics/Consumers/Kafka Connect. Перед загрузкой убедитесь, что source connector и его tasks RUNNING. Новый target должен быть RUNNING во время переноса; сохранённый старый target сейчас STOPPED намеренно, поскольку пользовательский Lakehouse пуст.
