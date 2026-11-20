package org.apache.iceberg.connect.data;

import demo.iceberg.EnvelopeToStaging;
import java.util.*;
import org.apache.iceberg.connect.IcebergSinkConfig;
import org.apache.iceberg.types.Types;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.errors.DataException;
import org.apache.kafka.connect.sink.SinkRecord;

public class EnvelopeToStagingCheck {
 static final String TOPIC="commerce.events.v1";
 static final String PAYLOAD="{\"event_id\":\"id-1\",\"event_type\":\"product\",\"entity_id\":\"P00001\",\"entity_version\":1,\"op\":\"U\",\"event_time\":\"2025-01-01T00:00:00Z\",\"payload\":{\"product_id\":\"P00001\",\"product_name\":\"Test\",\"category\":\"Test\"}}";
 static SinkRecord rec(String topic,int partition,long off,Object value){return new SinkRecord(topic,partition,Schema.STRING_SCHEMA,"product:P00001",Schema.STRING_SCHEMA,value,off);}
 static void ensure(boolean condition,String message){if(!condition)throw new AssertionError(message);}
 static void reject(EnvelopeToStaging transform,SinkRecord r,String reason){try{transform.apply(r);throw new AssertionError("not rejected: "+reason);}catch(DataException expected){}}
 public static void main(String[] args){
  EnvelopeToStaging t=new EnvelopeToStaging();t.configure(Map.of());
  SinkRecord result=t.apply(rec(TOPIC,3,123,PAYLOAD));Struct v=(Struct)result.value();
  ensure(v.getString("topic").equals(TOPIC),"topic");ensure(v.getInt32("kafka_partition")==3,"partition");
  ensure(v.getInt64("kafka_offset")==123,"offset");ensure(v.getInt64("batch_id")==((3L<<56)|123),"batch");
  ensure(v.getString("event_json").equals(PAYLOAD),"exact json");ensure(v.get("received_at")==null,"received_at");
  ensure(result.kafkaOffset()==123 && result.key().equals("product:P00001"),"metadata");
  Struct replay=(Struct)t.apply(rec(TOPIC,3,123,PAYLOAD)).value(); ensure(replay.equals(v),"replay deterministic");
  String deletion=PAYLOAD.replace("\"op\":\"U\"","\"op\":\"D\"");
  Struct updated=(Struct)t.apply(rec(TOPIC,3,124,deletion)).value();
  ensure(updated.getInt64("batch_id")!=v.getInt64("batch_id") && updated.getString("event_json").equals(deletion),"delete event");
  ensure(((Struct)t.apply(rec(TOPIC,127,(1L<<56)-1,PAYLOAD)).value()).getInt64("batch_id")==Long.MAX_VALUE,"range max");
  reject(t,rec("other",0,0,PAYLOAD),"topic");reject(t,rec(TOPIC,128,0,PAYLOAD),"partition");
  reject(t,rec(TOPIC,0,-1,PAYLOAD),"negative offset");reject(t,rec(TOPIC,0,1L<<56,PAYLOAD),"offset limit");
  reject(t,rec(TOPIC,0,0,null),"tombstone");reject(t,rec(TOPIC,0,0,"{"),"bad json");
  reject(t,rec(TOPIC,0,0,PAYLOAD.replace("\"entity_version\":1","\"entity_version\":0")),"version zero");
  reject(t,rec(TOPIC,0,0,PAYLOAD.replace("\"entity_version\":1","\"entity_version\":\"1\"")),"version type");
  reject(t,rec(TOPIC,0,0,PAYLOAD.replace("P00001\",\"product_name","P00002\",\"product_name")),"entity mismatch");
  reject(t,rec(TOPIC,0,0,PAYLOAD.replace("\"op\":\"U\"","\"op\":\"X\"")),"op");
  reject(t,rec(TOPIC,0,0,PAYLOAD.replace("2025-01-01T00:00:00Z","invalid")),"timestamp");
  reject(t,rec(TOPIC,0,0,PAYLOAD.replace("\"op\":\"U\"","\"op\":\"U\",\"op\":\"D\"")),"duplicate key");
  Map<String,String> config=Map.of("name","test", "iceberg.tables","demo.test", "iceberg.catalog.type","rest");
  Types.StructType mapped=SchemaUtils.toIcebergType(result.valueSchema(),new IcebergSinkConfig(config)).asStructType();
  ensure(mapped.field("topic").type().equals(Types.StringType.get()),"topic type");
  ensure(mapped.field("kafka_partition").type().equals(Types.IntegerType.get()),"partition type");
  ensure(mapped.field("kafka_offset").type().equals(Types.LongType.get()),"offset type");
  ensure(mapped.field("batch_id").type().equals(Types.LongType.get()),"batch type");
  ensure(mapped.field("received_at").type().equals(Types.TimestampType.withZone()),"timestamp with zone");
  ensure(mapped.field("event_json").type().equals(Types.StringType.get()),"json type");
  System.out.println("SMT_VALID_AND_REPLAY_PASS");System.out.println("SMT_INVALID_CASES_REJECTED");
  System.out.println("ICEBERG_TARGET_TYPES_PASS");t.close();
 }
}
