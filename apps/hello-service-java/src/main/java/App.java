import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.time.Instant;

import redis.clients.jedis.JedisPooled;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.ConnectionFactory;

import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import com.fasterxml.jackson.databind.ObjectMapper;

public class App {
  static class Secret {
    public String username;
    public String password;
    public String host;     // present in RDS-managed secrets
    public Integer port;    // present in RDS-managed secrets
    public String dbname;   // present in RDS-managed secrets
  }

  static Secret getSecret(String name, String region) {
    try {
      SecretsManagerClient sm = SecretsManagerClient.builder()
        .region(Region.of(region))
        .credentialsProvider(DefaultCredentialsProvider.create())
        .build();
      GetSecretValueResponse res = sm.getSecretValue(GetSecretValueRequest.builder().secretId(name).build());
      return new ObjectMapper().readValue(res.secretString(), Secret.class);
    } catch (Exception e) { return null; }
  }

  static String getenv(String k, String def) { String v = System.getenv(k); return (v == null || v.isBlank()) ? def : v; }

  public static void main(String[] args) throws Exception {
    String region = getenv("AWS_REGION", "ap-southeast-2");

    // ---- Postgres
    String rdsSecretId = getenv("RDS_SECRET_ID", "dev/rds/app");
  Secret db = getSecret(rdsSecretId, region);
  String dbUser = db != null && db.username != null ? db.username : getenv("POSTGRES_USER", "appuser");
  String dbPass = db != null && db.password != null ? db.password : getenv("POSTGRES_PASSWORD", "CHANGEME");
  String dbHost = (db != null && db.host != null) ? db.host : getenv("POSTGRES_HOST", "127.0.0.1");
  String dbPort = (db != null && db.port != null) ? Integer.toString(db.port) : getenv("POSTGRES_PORT", "5432");
  String dbName = (db != null && db.dbname != null) ? db.dbname : getenv("POSTGRES_DB", "appdb");

    String jdbcUrl = "jdbc:postgresql://" + dbHost + ":" + dbPort + "/" + dbName + "?sslmode=require";
    try (Connection con = DriverManager.getConnection(jdbcUrl, dbUser, dbPass); Statement st = con.createStatement()) {
      st.executeUpdate("CREATE TABLE IF NOT EXISTS hello (id SERIAL PRIMARY KEY, ts TIMESTAMPTZ DEFAULT NOW());");
      try (ResultSet rs = st.executeQuery("INSERT INTO hello DEFAULT VALUES RETURNING id;")) {
        rs.next(); System.out.println("Postgres insert OK: id=" + rs.getInt(1));
      }
    }

    // ---- Redis
    String redisHost = getenv("REDIS_HOST", "127.0.0.1");
    int redisPort = Integer.parseInt(getenv("REDIS_PORT", "6379"));
    try (JedisPooled jedis = new JedisPooled(redisHost, redisPort)) {
      long val = jedis.incr("hello:counter");
      System.out.println("Redis counter: " + val);
    }

    // ---- RabbitMQ (AMQPS)
  String mqSecretId = getenv("RABBITMQ_SECRET_ID", "dev/rabbitmq/app");
  Secret mq = getSecret(mqSecretId, region);
    String mqUser = mq != null ? mq.username : getenv("RABBITMQ_USER", "app");
    String mqPass = mq != null ? mq.password : getenv("RABBITMQ_PASS", "CHANGEME");
    String mqHost = getenv("RABBITMQ_HOST", "127.0.0.1");
    int mqPort = Integer.parseInt(getenv("RABBITMQ_PORT", "5671"));

    ConnectionFactory cf = new ConnectionFactory();
    cf.setHost(mqHost); cf.setPort(mqPort); cf.useSslProtocol();
    cf.setUsername(mqUser); cf.setPassword(mqPass);

    try (com.rabbitmq.client.Connection mqConn = cf.newConnection(); Channel ch = mqConn.createChannel()) {
      String ex = "events";
      ch.exchangeDeclare(ex, BuiltinExchangeType.TOPIC, true);
      String body = "{\"event\":\"hello\",\"ts\":\"" + Instant.now() + "\"}";
      ch.basicPublish(ex, "hello.created", null, body.getBytes(StandardCharsets.UTF_8));
      System.out.println("RabbitMQ publish OK");
    }

    // ---- S3 put/get
    String bucket = getenv("S3_BUCKET_NAME", null);
    if (bucket == null) throw new RuntimeException("S3_BUCKET_NAME not set");
    S3Client s3 = S3Client.builder().region(Region.of(region)).credentialsProvider(DefaultCredentialsProvider.create()).build();
    String key = "smoketest/hello-" + Instant.now().toEpochMilli() + ".txt";
    s3.putObject(PutObjectRequest.builder().bucket(bucket).key(key).build(),
      software.amazon.awssdk.core.sync.RequestBody.fromString("hello s3"));
    System.out.println("S3 put OK: s3://" + bucket + "/" + key);
    var obj = s3.getObject(GetObjectRequest.builder().bucket(bucket).key(key).build());
    String content = new String(obj.readAllBytes(), StandardCharsets.UTF_8);
    System.out.println("S3 get OK: " + content);
  }
}
