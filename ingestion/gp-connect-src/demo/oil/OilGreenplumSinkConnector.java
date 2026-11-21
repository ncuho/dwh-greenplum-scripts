package demo.oil;

import java.util.*;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.connect.connector.Task;
import org.apache.kafka.connect.sink.SinkConnector;

/** Single-task demo connector: offsets live transactionally in Greenplum. */
public final class OilGreenplumSinkConnector extends SinkConnector {

  private Map<String, String> config;

  @Override
  public void start(Map<String, String> props) {
    config = new HashMap<>(props);
  }

  @Override
  public Class<? extends Task> taskClass() {
    return OilGreenplumSinkTask.class;
  }

  @Override
  public List<Map<String, String>> taskConfigs(int maxTasks) {
    if (maxTasks != 1) throw new IllegalArgumentException(
      "tasks.max must be 1"
    );
    return Collections.singletonList(new HashMap<>(config));
  }

  @Override
  public void stop() {}

  @Override
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
  public String version() {
    return "0.1.0-demo";
  }
}
