# UmiGo Service Access Templates

Developers can use the environment variables provisioned on the EC2 instance (or exported locally) to connect to the managed services. This page provides minimal Java and CLI examples illustrating how to call each service.

## Finding the current Secret ARNs

Secrets Manager names rotate whenever RDS or RabbitMQ rotate credentials. Before pulling credentials, look up the actual ARN:

```powershell
aws secretsmanager list-secrets \
  --query "SecretList[].{Name:Name,Arn:ARN}" \
  --output table
```

Copy the ARN for the secret you need (e.g., the RDS or RabbitMQ entry), then fetch it:

```powershell
aws secretsmanager get-secret-value \
  --secret-id <ARN_FROM_LIST> \
  --query SecretString --output text
```

Set that ARN to `RDS_SECRET_ID` or `RABBITMQ_SECRET_ID` if you’re running locally.

## Port Forwarding Workflow

Use AWS Systems Manager (SSM) session tunneling to access cloud services from your laptop. After setting `AWS_PROFILE` or assuming the shared role:

- **Postgres** (RDS)
  ```powershell
  aws ssm start-session \
    --region ap-southeast-2 \
    --target i-03801fee7b905eb4f \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["5432"],"localPortNumber":["15432"]}'
  ```
  Leave the window running; connect from your IDE as `host=localhost`, `port=15432` with credentials from the secret.

- **Redis** (ElastiCache)
  ```powershell
  aws ssm start-session \
    --region ap-southeast-2 \
    --target i-03801fee7b905eb4f \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["6379"],"localPortNumber":["16379"]}'
  ```
  Then run `redis-cli -h 127.0.0.1 -p 16379 ping`.

- **RabbitMQ** (Amazon MQ)
  ```powershell
  aws ssm start-session \
    --region ap-southeast-2 \
    --target i-03801fee7b905eb4f \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["5671"],"localPortNumber":["15671"]}'
  ```
  Use an AMQP client against `amqps://localhost:15671` with credentials from the secret.

Repeat for any other ports. Close the session when done (Ctrl+C).

## Common Environment Variables

```text
AWS_REGION
RDS_SECRET_ID            # contains username/password and optional host/port/dbname
POSTGRES_HOST / PORT / DB (optional overrides)
S3_BUCKET_NAME
REDIS_HOST / REDIS_PORT
RABBITMQ_HOST / RABBITMQ_PORT
RABBITMQ_SECRET_ID
```

## Secrets Manager helper (reuse)
```java
import com.fasterxml.jackson.databind.ObjectMapper;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;

record DbSecret(String username, String password, String host, Integer port, String dbname) {}

static DbSecret getSecret(String id, String region) {
  try {
    SecretsManagerClient sm = SecretsManagerClient.builder()
      .region(Region.of(region))
      .credentialsProvider(DefaultCredentialsProvider.create())
      .build();
    GetSecretValueResponse res = sm.getSecretValue(
      GetSecretValueRequest.builder().secretId(id).build());
    return new ObjectMapper().readValue(res.secretString(), DbSecret.class);
  } catch (Exception e) {
    throw new RuntimeException("Unable to read secret " + id, e);
  }
}
```

## Postgres (JDBC)
```java
DbSecret db = getSecret(System.getenv("RDS_SECRET_ID"), System.getenv("AWS_REGION"));
String host = db.host() != null ? db.host() : System.getenv("POSTGRES_HOST");
String port = db.port() != null ? db.port().toString() : System.getenv("POSTGRES_PORT", "5432");
String dbName = db.dbname() != null ? db.dbname() : System.getenv("POSTGRES_DB", "appdb");
String user = db.username();
String pass = db.password();
String jdbcUrl = "jdbc:postgresql://" + host + ":" + port + "/" + dbName + "?sslmode=require";

try (Connection con = DriverManager.getConnection(jdbcUrl, user, pass);
     Statement st = con.createStatement();
     ResultSet rs = st.executeQuery("SELECT now()")) {
  if (rs.next()) {
    System.out.println("DB time: " + rs.getTimestamp(1));
  }
}
```

## Redis (Jedis)
```java
String redisHost = System.getenv("REDIS_HOST");
int redisPort = Integer.parseInt(System.getenv("REDIS_PORT", "6379"));
try (JedisPooled jedis = new JedisPooled(redisHost, redisPort)) {
  long count = jedis.incr("hello:counter");
  System.out.println("Counter=" + count);
}
```

## RabbitMQ (AMQPS)
```java
DbSecret mq = getSecret(System.getenv("RABBITMQ_SECRET_ID"), System.getenv("AWS_REGION"));
String mqHost = System.getenv("RABBITMQ_HOST");
int mqPort = Integer.parseInt(System.getenv("RABBITMQ_PORT", "5671"));
ConnectionFactory factory = new ConnectionFactory();
factory.setHost(mqHost);
factory.setPort(mqPort);
factory.useSslProtocol();
factory.setUsername(mq.username());
factory.setPassword(mq.password());

try (com.rabbitmq.client.Connection conn = factory.newConnection();
     Channel channel = conn.createChannel()) {
  channel.exchangeDeclare("events", BuiltinExchangeType.TOPIC, true);
  channel.basicPublish("events", "demo.test", null, "Hello MQ".getBytes(StandardCharsets.UTF_8));
}
```

## S3 (AWS SDK v2)
```java
S3Client s3 = S3Client.builder()
  .region(Region.of(System.getenv("AWS_REGION")))
  .credentialsProvider(DefaultCredentialsProvider.create())
  .build();
String bucket = System.getenv("S3_BUCKET_NAME");
String key = "samples/" + Instant.now().toEpochMilli() + ".txt";

s3.putObject(PutObjectRequest.builder().bucket(bucket).key(key).build(),
  RequestBody.fromString("hello from dev"));
String body = new String(s3.getObject(GetObjectRequest.builder().bucket(bucket).key(key).build()).readAllBytes(), StandardCharsets.UTF_8);
System.out.println(body);
```

## Assorted AWS CLI snippets
- `aws sts get-caller-identity`
- `aws ec2 describe-instances --filters Name=tag:Name,Values=umigo-dev-ec2 Name=instance-state-name,Values=running`
- `aws rds describe-db-instances --db-instance-identifier umigo-dev-pg`
- `aws elasticache describe-cache-clusters --cache-cluster-id umigo-dev-redis --show-cache-node-info`
- `aws mq describe-broker --broker-id <broker-id>`
- `aws secretsmanager get-secret-value --secret-id <ARN_FROM_LIST>`

Copy/adapt these patterns whenever you integrate with the services from code or CLI.
