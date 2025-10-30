# AWS smoke test (dev): run Hello Service on EC2 via SSM

Prerequisites:
- AWS CLI configured with profile umigo-dev
- Permissions for EC2, RDS, and SSM
- Region: ap-southeast-2

## 1) Use your developer profile
```powershell
$env:AWS_PROFILE = 'umigo-dev'
aws sts get-caller-identity   # optional check
```

## 2) Discover EC2 instance and RDS info
```powershell
$INSTANCE = aws ec2 describe-instances `
    --filters "Name=tag:Name,Values=umigo-dev-ec2" `
                     "Name=tag:Project,Values=Starter" `
                     "Name=tag:Env,Values=dev" `
                     "Name=instance-state-name,Values=running" `
    --query "Reservations[].Instances[].InstanceId" `
    --output text

$postgresHost = aws rds describe-db-instances `
    --db-instance-identifier umigo-dev-pg `
    --query "DBInstances[0].Endpoint.Address" `
    --output text

$postgresDb = aws rds describe-db-instances `
    --db-instance-identifier umigo-dev-pg `
    --query "DBInstances[0].DBName" `
    --output text
```

## 3) Run the smoke test via SSM
```powershell
$commands = @(
    'set -e',
    "cd /home/ec2-user/aws-dev-env/apps/hello-service-java && . /etc/hello-service.env && POSTGRES_HOST=$postgresHost POSTGRES_DB=$postgresDb POSTGRES_PORT=5432 mvn -q clean compile -DskipTests exec:java -Dexec.mainClass=App"
)

$payload = @{
    InstanceIds  = @($INSTANCE)
    DocumentName = 'AWS-RunShellScript'
    Parameters   = @{ commands = $commands }
} | ConvertTo-Json -Compress

$tmp = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmp, $payload, (New-Object System.Text.UTF8Encoding $false))

$cmdId = aws ssm send-command `
    --region ap-southeast-2 `
    --cli-input-json ("file://$tmp") `
    --query "Command.CommandId" `
    --output text

Remove-Item $tmp

aws ssm get-command-invocation `
    --region ap-southeast-2 `
    --command-id $cmdId `
    --instance-id $INSTANCE `
    --query "{Status:Status,StdOut:StandardOutputContent,StdErr:StandardErrorContent}" `
    --output json

```
expected output looks like: 
```
{
    "Status": "Success",
    "StdOut": "Postgres insert OK: id=4\nRedis counter: 4\nRabbitMQ publish OK\nS3 put OK: s3://umigo-dev-app-bucket/smoketest/hello-1761308033087.txt\nS3 get OK: hello s3\n",
    "StdErr": "SLF4J: Failed to load class \"org.slf4j.impl.StaticLoggerBinder\".\nSLF4J: Defaulting to no-operation (NOP) logger implementation\nSLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.\n"
}
```

