package demo.oil;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonParser;
import java.time.OffsetDateTime;
import java.util.Map;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.SchemaBuilder;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.errors.DataException;
import org.apache.kafka.connect.sink.SinkRecord;
import org.apache.kafka.connect.transforms.Transformation;

/** Proposal: single-topic per-record staging mapping; not installed or tested. */
public final class OilEnvelopeToStaging implements Transformation<SinkRecord> {
  private static final String DEFAULT_TOPIC="oil.events.v1";
  private String allowedTopic=DEFAULT_TOPIC;
  private static final long OFFSET_LIMIT=1L << 56;
  private static final ObjectMapper JSON=new ObjectMapper().enable(JsonParser.Feature.STRICT_DUPLICATE_DETECTION);
  private static final Schema SCHEMA=SchemaBuilder.struct().name("demo.StagingEvent")
      .field("topic",Schema.STRING_SCHEMA)
      .field("kafka_partition",Schema.INT32_SCHEMA)
      .field("kafka_offset",Schema.INT64_SCHEMA)
      .field("batch_id",Schema.INT64_SCHEMA)
      .field("received_at",org.apache.kafka.connect.data.Timestamp.builder().optional().build())
      .field("event_json",Schema.STRING_SCHEMA).build();
  @Override public SinkRecord apply(SinkRecord record) {
    Integer p=record.kafkaPartition(); long offset=record.kafkaOffset();
    if(!allowedTopic.equals(record.topic()) || p==null || p<0 || p>127 || offset<0 || offset>=OFFSET_LIMIT)
      throw new DataException("staging topic/partition/offset outside contract");
    if(!(record.value() instanceof String)) throw new DataException("JSON StringConverter required; tombstone unsupported");
    String text=(String)record.value();
    try {
      JsonNode node=JSON.readTree(text);
      if(node==null || !node.isObject()) throw new DataException("JSON object required");
      if(!node.has("schema_version") || !node.get("schema_version").isIntegralNumber() || !node.get("schema_version").canConvertToInt() || node.get("schema_version").asInt()!=1) throw new DataException("unsupported schema_version");
      for(String key:new String[]{"event_id","event_type","entity_id","entity_version","op","event_time","payload"})
        if(!node.hasNonNull(key)) throw new DataException("missing required envelope field: "+key);
      for(String key:new String[]{"event_id","event_type","entity_id","op","event_time"})
        if(!node.get(key).isTextual() || node.get(key).asText().trim().isEmpty())
          throw new DataException("invalid envelope text field: "+key);
      if(!node.get("entity_version").isIntegralNumber() || !node.get("entity_version").canConvertToLong() || node.get("entity_version").asLong()<1)
        throw new DataException("entity_version must be a positive int64");
      if(!node.get("payload").isObject() || !("U".equals(node.get("op").asText()) || "D".equals(node.get("op").asText())))
        throw new DataException("invalid envelope payload or op");
      String eventType=node.get("event_type").asText();
      if(!java.util.Set.of("field","well","production_day","downtime").contains(eventType))
        throw new DataException("unsupported event type");
      JsonNode payloadId=node.get("payload").get("production_day".equals(eventType)?"production_id":eventType+"_id");
      if(payloadId==null || !payloadId.isTextual() || !payloadId.asText().equals(node.get("entity_id").asText()))
        throw new DataException("entity_id does not match payload identifier");
      OffsetDateTime.parse(node.get("event_time").asText());
    } catch(DataException e) { throw e; } catch(Exception e) { throw new DataException("invalid JSON envelope"); }
    long batch=((long)p << 56) | offset;
    Struct value=new Struct(SCHEMA).put("topic",record.topic()).put("kafka_partition",p)
      .put("kafka_offset",offset).put("batch_id",batch).put("received_at",null).put("event_json",text);
    return record.newRecord(record.topic(),p,record.keySchema(),record.key(),SCHEMA,value,record.timestamp());
  }
  @Override public ConfigDef config() {
    return new ConfigDef().define("allowed.topic",ConfigDef.Type.STRING,DEFAULT_TOPIC,ConfigDef.Importance.HIGH,"Exactly one permitted source topic");
  }
  @Override public void configure(Map<String,?> props) {
    Object topic=props.get("allowed.topic");
    if(topic!=null) {
      if(!(topic instanceof String) || !((String)topic).matches("[A-Za-z0-9._-]{1,249}"))
        throw new IllegalArgumentException("invalid allowed.topic");
      allowedTopic=(String)topic;
    }
  }
  @Override public void close() { }
}
