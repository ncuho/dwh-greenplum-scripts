package demo.oil;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.util.*;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.connect.errors.ConnectException;
import org.apache.kafka.connect.sink.SinkRecord;
import org.apache.kafka.connect.sink.SinkTask;

/** GP commit is authoritative; no automatic checkpoint initialization. */
public final class OilGreenplumSinkTask extends SinkTask {
    private Connection db;
    private String schema;
    private final Map<TopicPartition,Long> positions = new HashMap<>();
    @Override public String version() { return "0.1.0-demo"; }
    @Override public void start(Map<String,String> cfg) {
        try {
            schema = cfg.getOrDefault("gp.schema", "oil_stg");
            if (!schema.matches("[a-z_][a-z0-9_]*")) throw new ConnectException("invalid GP schema name");
            String url = cfg.get("gp.jdbc.url");
            if (url == null || !url.contains("sslmode=verify-full") || !url.contains("sslrootcert="))
                throw new ConnectException("GP requires sslmode=verify-full and sslrootcert");
            String password = Files.readString(Path.of(cfg.get("gp.password.file")), StandardCharsets.UTF_8).stripTrailing();
            Properties props = new Properties(); props.setProperty("user", cfg.get("gp.user")); props.setProperty("password", password);
            db = DriverManager.getConnection(url, props); db.setAutoCommit(false);
        } catch (Exception ex) { throw new ConnectException("GP connection failed", ex); }
    }
    @Override public void open(Collection<TopicPartition> partitions) {
        try {
            for (TopicPartition tp : partitions) {
                try (PreparedStatement s = db.prepareStatement(sql("SELECT next_offset FROM demo_stg.kafka_checkpoint WHERE topic=? AND kafka_partition=?"))) {
                    s.setString(1,tp.topic()); s.setInt(2,tp.partition());
                    try (ResultSet r=s.executeQuery()) {
                        if (!r.next()) throw new ConnectException("missing reviewed GP checkpoint for " + tp);
                        long next=r.getLong(1); positions.put(tp,next); context.offset(tp,next);
                    }
                }
            }
            db.commit();
        } catch (SQLException ex) { rollback(); throw new ConnectException("cannot load checkpoints",ex); }
    }
    @Override public void put(Collection<SinkRecord> records) {
        for (SinkRecord record : records) {
            TopicPartition tp = new TopicPartition(record.topic(), record.kafkaPartition());
            if (!(record.value() instanceof String)) throw new ConnectException("StringConverter JSON value required; tombstones unsupported");
            Long expected=positions.get(tp);
            if (expected==null || record.kafkaOffset()!=expected)
                throw new ConnectException("offset mismatch " + tp + ": expected " + expected + " got " + record.kafkaOffset());
            try {
                try (Statement s=db.createStatement()) { s.execute(sql("LOCK TABLE demo_stg.kafka_checkpoint IN EXCLUSIVE MODE")); }
                try (PreparedStatement s=db.prepareStatement(sql("SELECT next_offset FROM demo_stg.kafka_checkpoint WHERE topic=? AND kafka_partition=?"))) {
                    s.setString(1,tp.topic()); s.setInt(2,tp.partition());
                    try(ResultSet r=s.executeQuery()) { if (!r.next() || r.getLong(1)!=expected) throw new SQLException("checkpoint ownership changed"); }
                }
                long batch;
                try (Statement s=db.createStatement(); ResultSet r=s.executeQuery(sql("SELECT nextval('demo_stg.kafka_batch_id_seq')"))) { r.next(); batch=r.getLong(1); }
                String manifest=String.format(Locale.ROOT,"{\"partition\":%d,\"first_offset\":%d,\"next_offset\":%d,\"count\":1}",tp.partition(),expected,expected+1);
                try (PreparedStatement s=db.prepareStatement(sql("INSERT INTO demo_stg.batch_control(batch_id,source_name,status,source_manifest) VALUES (?,?,'OPEN',?)"))) {
                    s.setLong(1,batch);s.setString(2,"kafka:"+tp.topic());s.setString(3,manifest);s.executeUpdate();
                }
                try (PreparedStatement s=db.prepareStatement(sql("INSERT INTO demo_stg.event_log(topic,kafka_partition,kafka_offset,batch_id,event_json) VALUES (?,?,?,?,?)"))) {
                    s.setString(1,tp.topic());s.setInt(2,tp.partition());s.setLong(3,expected);s.setLong(4,batch);s.setString(5,(String)record.value());s.executeUpdate();
                }
                try (PreparedStatement s=db.prepareStatement(sql("UPDATE demo_stg.batch_control SET status='READY' WHERE batch_id=?"))) { s.setLong(1,batch);s.executeUpdate(); }
                try (PreparedStatement s=db.prepareStatement(sql("UPDATE demo_stg.kafka_checkpoint SET next_offset=?,updated_at=now() WHERE topic=? AND kafka_partition=?"))) {
                    s.setLong(1,expected+1);s.setString(2,tp.topic());s.setInt(3,tp.partition()); if(s.executeUpdate()!=1) throw new SQLException("checkpoint update failed");
                }
                db.commit(); positions.put(tp,expected+1);
            } catch (Exception ex) { rollback(); throw new ConnectException("GP staging transaction failed; restart from GP checkpoint",ex); }
        }
    }
    @Override public Map<TopicPartition,OffsetAndMetadata> preCommit(Map<TopicPartition,OffsetAndMetadata> current) {
        Map<TopicPartition,OffsetAndMetadata> result=new HashMap<>();
        for (Map.Entry<TopicPartition,OffsetAndMetadata> e: current.entrySet()) {
            Long p=positions.get(e.getKey()); if(p!=null) result.put(e.getKey(),new OffsetAndMetadata(p));
        }
        return result;
    }
    @Override public void close(Collection<TopicPartition> partitions) { for (TopicPartition tp:partitions) positions.remove(tp); }
    @Override public void stop() { if(db!=null) try { db.close(); } catch(SQLException ignored) { } }
    private void rollback() { if(db!=null) try { db.rollback(); } catch(SQLException ignored) { } }
    private String sql(String statement) { return statement.replace("demo_stg.", schema + "."); }
}
