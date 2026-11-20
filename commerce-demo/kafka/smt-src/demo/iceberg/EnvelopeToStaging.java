package demo.iceberg;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.SchemaBuilder;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.errors.DataException;
import org.apache.kafka.connect.sink.SinkRecord;
import org.apache.kafka.connect.transforms.Transformation;

/** Proposal: single-topic per-record staging mapping; not installed or tested. */
public final class EnvelopeToStaging implements Transformation<SinkRecord> {
  private static final String TOPIC="commerce.events.v1";
  private static final long OFFSET_LIMIT=1L << 56;
  private static final ObjectMapper JSON=new ObjectMapper();
  private static final Schema SCHEMA=SchemaBuilder.struct().name("demo.StagingEvent")
      .field("topic",Schema.STRING_SCHEMA)
      .field("kafka_partition",Schema.INT32_SCHEMA)
      .field("kafka_offset",Schema.INT64_SCHEMA)
      .field("batch_id",Schema.INT64_SCHEMA)
      .field("received_at",org.apache.kafka.connect.data.Timestamp.builder().optional().build())
      .field("event_json",Schema.STRING_SCHEMA).build();
  @Override public SinkRecord apply(SinkRecord record) {
    Integer p=record.kafkaPartition(); long offset=record.kafkaOffset();
    if(!TOPIC.equals(record.topic()) || p==null || p<0 || p>127 || offset<0 || offset>=OFFSET_LIMIT)
      throw new DataException("staging topic/partition/offset outside contract");
    if(!(record.value() instanceof String)) throw new DataException("JSON StringConverter required; tombstone unsupported");
    String text=(String)record.value();
    try {
      JsonNode node=JSON.readTree(text);
      if(node==null || !node.isObject()) throw new DataException("JSON object required");
      for(String key:new String[]{"event_id","event_type","entity_id","entity_version","op","event_time","payload"})
        if(!node.hasNonNull(key)) throw new DataException("missing required envelope field: "+key);
      if(!node.get("payload").isObject() || !("U".equals(node.get("op").asText()) || "D".equals(node.get("op").asText())))
        throw new DataException("invalid envelope payload or op");
    } catch(DataException e) { throw e; } catch(Exception e) { throw new DataException("invalid JSON envelope"); }
    long batch=((long)p << 56) | offset;
    Struct value=new Struct(SCHEMA).put("topic",record.topic()).put("kafka_partition",p)
      .put("kafka_offset",offset).put("batch_id",batch).put("received_at",null).put("event_json",text);
    return record.newRecord(record.topic(),p,record.keySchema(),record.key(),SCHEMA,value,record.timestamp());
  }
  @Override public ConfigDef config() {return new ConfigDef();}
  @Override public void configure(Map<String,?> props) { }
  @Override public void close() { }
}
