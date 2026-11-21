import java.util.*;
import org.apache.iceberg.Table;
import org.apache.iceberg.catalog.TableIdentifier;
import org.apache.iceberg.rest.RESTCatalog;
import org.apache.iceberg.data.IcebergGenerics;
import org.apache.iceberg.data.Record;
import org.apache.iceberg.io.CloseableIterable;
import com.fasterxml.jackson.databind.*;
public class OilReadbackProbe {
 public static void main(String[] args) throws Exception {
  Map<String,String> p=new HashMap<>();p.put("uri","https://10.0.2.16/catalog");p.put("warehouse","dlh");
  p.put("rest.auth.type","demo.iceberg.CiamAuthManager");p.put("ciam.credential-file","/etc/kafka-demo/iceberg-client-credential");
  p.put("io-impl","org.apache.iceberg.aws.s3.S3FileIO");p.put("s3.endpoint","https://hb.ru-msk.vkcloud-storage.ru");
  p.put("client.region","ru-msk");p.put("s3.path-style-access","true");p.put("s3.remote-signing-enabled","true");p.put("header.X-Iceberg-Access-Delegation","remote-signing");
  try(RESTCatalog c=new RESTCatalog()) {
   c.initialize("oil-probe",p);Table t=c.loadTable(TableIdentifier.of("oil_ingest_probe_20261122","event_log"));
   TreeMap<Long,String> docs=new TreeMap<>(); ObjectMapper json=new ObjectMapper(); boolean valid=true;
   try(CloseableIterable<Record> rows=IcebergGenerics.read(t).build()) {
    for(Record r:rows){ long off=((Number)r.getField("kafka_offset")).longValue();String v=String.valueOf(r.getField("event_json"));
     valid &= docs.put(off,v)==null && "oil-ingest-probe-events-20261122".equals(r.getField("topic")) && ((Number)r.getField("kafka_partition")).intValue()==0 && ((Number)r.getField("batch_id")).longValue()==off && r.getField("received_at")==null;
    }
   }
   valid &= docs.keySet().equals(new TreeSet<>(Arrays.asList(0L,1L,2L,3L,4L)));
   if(docs.size()==5){ valid &= docs.get(0L).equals(docs.get(1L)) && docs.get(0L).equals(docs.get(4L));
    JsonNode a=json.readTree(docs.get(0L)),b=json.readTree(docs.get(2L)),d=json.readTree(docs.get(3L));
    valid &= "oil-probe-e1".equals(a.get("event_id").asText()) && "oil-probe-e2".equals(b.get("event_id").asText()) && "oil-probe-e3".equals(d.get("event_id").asText()) && "D".equals(d.get("op").asText());
   }
   System.out.println("OIL_PROBE_COUNT="+docs.size());System.out.println("OIL_PROBE_OFFSETS="+docs.keySet());System.out.println("OIL_PROBE_REPLAY_U_D_MATCH="+valid);
   if(!valid)throw new IllegalStateException("probe mismatch");
  }
 }
}
