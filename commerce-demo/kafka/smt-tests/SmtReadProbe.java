import java.util.*;
import org.apache.iceberg.Table;
import org.apache.iceberg.catalog.TableIdentifier;
import org.apache.iceberg.rest.RESTCatalog;
import org.apache.iceberg.data.IcebergGenerics;
import org.apache.iceberg.data.Record;
import org.apache.iceberg.io.CloseableIterable;
public class SmtReadProbe {
 public static void main(String[] args) throws Exception {
  Map<String,String> p=new HashMap<>();
  p.put("uri","https://10.0.2.16/catalog");p.put("warehouse","dlh");
  p.put("rest.auth.type","demo.iceberg.CiamAuthManager");
  p.put("ciam.credential-file","/etc/kafka-demo/iceberg-client-credential");
  p.put("io-impl","org.apache.iceberg.aws.s3.S3FileIO");
  p.put("s3.endpoint","https://hb.ru-msk.vkcloud-storage.ru");p.put("client.region","ru-msk");
  p.put("s3.path-style-access","true");p.put("s3.remote-signing-enabled","true");
  p.put("header.X-Iceberg-Access-Delegation","remote-signing");
  try(RESTCatalog catalog=new RESTCatalog()) {
   catalog.initialize("probe",p);
   Table table=catalog.loadTable(TableIdentifier.of("kafka_smt_20261120_dedcccf0","sink_smt_probe"));
   int count=0; java.util.Set<Long> offsets=new java.util.HashSet<>(); boolean valid=true;
   try(CloseableIterable<Record> records=IcebergGenerics.read(table).build()) {
    for(Record record:records) {
     count++; long off=((Number)record.getField("kafka_offset")).longValue(); offsets.add(off);
     valid &= "webinar-smt-probe-events-20261120".equals(record.getField("topic")) && ((Number)record.getField("kafka_partition")).intValue()==0 && ((Number)record.getField("batch_id")).longValue()==off && record.getField("received_at")==null;
     com.fasterxml.jackson.databind.JsonNode json=new com.fasterxml.jackson.databind.ObjectMapper().readTree(String.valueOf(record.getField("event_json")));
     String expectedId=off<2?"smt-probe-1":off==2?"smt-probe-2":"smt-probe-3";
     valid &= expectedId.equals(json.get("event_id").asText()) && (off==3?"D":"U").equals(json.get("op").asText());
    }
   }
   boolean timestampZone=table.schema().findField("received_at").type().equals(org.apache.iceberg.types.Types.TimestampType.withZone());
   System.out.println("SMT_READ_COUNT="+count);System.out.println("SMT_OFFSETS="+new java.util.TreeSet<>(offsets));System.out.println("SMT_VALUES_MATCH="+valid);System.out.println("SMT_TIMESTAMP_WITH_ZONE="+timestampZone);
   if(count!=4 || !offsets.equals(java.util.Set.of(0L,1L,2L,3L)) || !valid || !timestampZone)throw new IllegalStateException("unexpected staging content");
  }
 }
}
