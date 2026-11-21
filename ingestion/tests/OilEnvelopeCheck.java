import demo.oil.OilEnvelopeToStaging;
import java.util.Map;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.errors.DataException;
import org.apache.kafka.connect.sink.SinkRecord;
public class OilEnvelopeCheck {
 static SinkRecord record(String value,long offset){return new SinkRecord("oil.events.v1",2,Schema.STRING_SCHEMA,"k",Schema.STRING_SCHEMA,value,offset);}
 public static void main(String[] args){
  String json="{\"schema_version\":1,\"event_id\":\"e1\",\"event_type\":\"production_day\",\"entity_id\":\"W00001_20250101\",\"entity_version\":1,\"op\":\"U\",\"event_time\":\"2025-01-01T12:00:00Z\",\"payload\":{\"production_id\":\"W00001_20250101\"}}";
  OilEnvelopeToStaging t=new OilEnvelopeToStaging();t.configure(Map.of()); Struct v=(Struct)t.apply(record(json,3)).value();
  if(!json.equals(v.getString("event_json")) || v.getInt32("kafka_partition")!=2 || v.getInt64("kafka_offset")!=3 || v.getInt64("batch_id")!=((2L<<56)|3) || v.get("received_at")!=null) throw new AssertionError("mapping");
  if(!v.equals(t.apply(record(json,3)).value())) throw new AssertionError("replay");
  try {t.apply(record(json.replace("\"schema_version\":1","\"schema_version\":2"),3));throw new AssertionError("unknown schema accepted");} catch(DataException expected) { }
  try {t.apply(record(json.replace("W00001_20250101\"}}","W00002_20250101\"}}"),3));throw new AssertionError("wrong id accepted");} catch(DataException expected) { }
  System.out.println("OIL_SMT_OFFLINE_PASS");
 }
}
