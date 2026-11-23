package demo.oil;

import java.util.*;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.connect.connector.Task;
import org.apache.kafka.connect.sink.SinkConnector;

/** Single-task Greenplum connector: offsets live transactionally in Greenplum. */
public final class OilGreenplumSinkConnector extends SinkConnector {

  private Map<String, String> config;

  @Override
  /** Проверяет конфигурацию и инициализирует ресурсы connector/task. */
  public void start(Map<String, String> props) {
    config = new HashMap<>(props);
  }

  @Override
  /** Возвращает тип исполняемой SinkTask для данного connector. */
  public Class<? extends Task> taskClass() {
    return OilGreenplumSinkTask.class;
  }

  @Override
  /** Передаёт проверенную конфигурацию каждой создаваемой Connect task. */
  public List<Map<String, String>> taskConfigs(int maxTasks) {
    if (maxTasks != 1) throw new IllegalArgumentException(
      "tasks.max must be 1"
    );
    return Collections.singletonList(new HashMap<>(config));
  }

  @Override
  /** Завершает работу плагина и закрывает принадлежащее task соединение. */
  public void stop() {}

  @Override
  /** Возвращает ConfigDef параметров плагина для штатной Connect validation. */
  public ConfigDef config() {
    return new ConfigDef()
      .define(
        "gp.jdbc.url",
        ConfigDef.Type.STRING,
        ConfigDef.Importance.HIGH,
        "GP JDBC URL, SSL verify-full required"
      )
      .define(
        "gp.user",
        ConfigDef.Type.STRING,
        ConfigDef.Importance.HIGH,
        "GP service user"
      )
      .define(
        "gp.schema",
        ConfigDef.Type.STRING,
        "oil_stg",
        ConfigDef.Importance.MEDIUM,
        "Dedicated staging schema"
      )
      .define(
        "gp.password.file",
        ConfigDef.Type.STRING,
        ConfigDef.Importance.HIGH,
        "Path to owner-only password file on worker"
      );
  }

  @Override
  /** Возвращает версию установленной реализации Kafka Connect plugin. */
  public String version() {
    return "0.1.0-demo";
  }
}
