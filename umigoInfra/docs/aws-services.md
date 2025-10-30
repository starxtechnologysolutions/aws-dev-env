# UmiGo AWS Services Quick Reference

This document collects the key connection details, CLI snippets, and smoke-test commands for the shared UmiGo development environment (`project=Starter`, `env=dev`). Use it whenever you need to reach a managed service directly or verify the stack.

## Common Environment Variables

| Variable | Source/Meaning |
|----------|----------------|
| `AWS_REGION` | Deployment region (`ap-southeast-2`) |
| `RDS_SECRET_ID` | Secrets Manager secret holding Postgres credentials (`dev/rds/app`) |
| `S3_BUCKET_NAME` | Application bucket (`umigo-dev-app-bucket`) |
| `REDIS_HOST` | ElastiCache Redis endpoint |
| `REDIS_PORT` | Redis port (`6379`) |
| `RABBITMQ_HOST` | Amazon MQ host |
| `RABBITMQ_PORT` | RabbitMQ TLS port (`5671`) |
| `RABBITMQ_SECRET_ID` | RabbitMQ credentials secret (`dev/rabbitmq/app`) |

These entries are written to `/etc/hello-service.env` on the EC2 instance via `scripts/ssm_write_env.ps1`.

## Postgres (Amazon RDS)

- Instance identifier: `umigo-dev-pg`
- Hostname:
  ```bash
  aws rds describe-db-instances \
    --db-instance-identifier umigo-dev-pg \
    --query "DBInstances[0].Endpoint.Address" --output text
  ```
- Database name: `appdb`
- Credentials: stored in `dev/rds/app` secret (requires `secretsmanager:GetSecretValue`).
  ```bash
  aws secretsmanager get-secret-value --secret-id dev/rds/app --query SecretString --output text | jq .
  ```
- psql example:
  ```bash
  psql "host=<hostname> port=5432 dbname=appdb user=<username> password=<password> sslmode=require"
  ```

## Redis (Amazon ElastiCache)

- Cluster ID: `umigo-dev-redis`
- Hostname:
  ```bash
  aws elasticache describe-cache-clusters \
    --cache-cluster-id umigo-dev-redis --show-cache-node-info \
    --query "CacheClusters[0].CacheNodes[0].Endpoint.Address" --output text
  ```
- Port: `6379`
- redis-cli example:
  ```bash
  redis-cli -h <redis-host> -p 6379 ping
  redis-cli -h <redis-host> -p 6379 get hello:counter
  ```

## RabbitMQ (Amazon MQ)

- Broker name: `umigo-dev-rabbit`
- Host: `b-....mq.ap-southeast-2.on.aws`
- Port: `5671`
- Credentials: stored in `dev/rabbitmq/app` secret.
- TLS test:
  ```bash
  openssl s_client -connect <mq-host>:5671 -servername <mq-host> -quiet
  ```
  Expect to see the certificate chain followed by `AMQP`.

## S3 Bucket

- Bucket name: `umigo-dev-app-bucket`
- Examples:
  ```bash
  aws s3 ls s3://umigo-dev-app-bucket
  aws s3 cp file.txt s3://umigo-dev-app-bucket/smoketest/file.txt
  aws s3 rm s3://umigo-dev-app-bucket/smoketest/file.txt
  ```

## Secrets Manager

- Postgres secret: `dev/rds/app`
- RabbitMQ secret: `dev/rabbitmq/app`
- Fetch a secret (needs `secretsmanager:GetSecretValue`):
  ```bash
  aws secretsmanager get-secret-value --secret-id dev/rds/app --query SecretString --output text
  ```

## Smoke Test via SSM

```powershell
# assumes AWS_PROFILE or STS session is set
$INSTANCE = aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=umigo-dev-ec2" "Name=tag:Env,Values=dev" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text

$commands = @(
  'set -e',
  'cd /home/ec2-user/aws-dev-env/apps/hello-service-java && . /etc/hello-service.env && POSTGRES_HOST=umigo-dev-pg.crk68s8owy0c.ap-southeast-2.rds.amazonaws.com POSTGRES_DB=appdb POSTGRES_PORT=5432 mvn -q clean compile -DskipTests exec:java -Dexec.mainClass=App'
)

$payload = @{ InstanceIds=@($INSTANCE); DocumentName='AWS-RunShellScript'; Parameters=@{ commands=$commands } } | ConvertTo-Json -Compress
$tmp = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmp, $payload, (New-Object System.Text.UTF8Encoding $false))
$cmdId = aws ssm send-command --region ap-southeast-2 --cli-input-json ("file://$tmp") --query "Command.CommandId" --output text
Remove-Item $tmp
aws ssm get-command-invocation --region ap-southeast-2 --command-id $cmdId --instance-id $INSTANCE --query "{Status:Status,StdOut:StandardOutputContent,StdErr:StandardErrorContent}" --output json
```

Success looks like:
```
Postgres insert OK: id=бн
Redis counter: бн
RabbitMQ publish OK
S3 put OK: бн
S3 get OK: hello s3
```

## Helpful CLI Checks

```bash
aws sts get-caller-identity
aws ec2 describe-instances --filters Name=tag:Name,Values=umigo-dev-ec2 Name=tag:Env,Values=dev
aws rds describe-db-instances --db-instance-identifier umigo-dev-pg
aws elasticache describe-cache-clusters --cache-cluster-id umigo-dev-redis --show-cache-node-info
aws mq describe-broker --broker-id <broker-id>
aws s3 ls s3://umigo-dev-app-bucket
```
