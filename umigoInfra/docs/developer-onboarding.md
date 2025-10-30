# Developer Onboarding Guide

This guide walks a new developer through verifying access to the shared `starter-dev` environment. Infrastructure is already provisioned and the EC2 instance includes Java, Maven, the repo checkout, and service credentials - no Terraform or package installs should be performed from a developer laptop.

## 1. Prerequisites

Install locally:

- AWS CLI v2 (`aws --version`)
- PowerShell 7 (or Windows PowerShell 5.1) for the helper scripts
- Optional: Git if you prefer to pull the repo for reference

Request access to the shared IAM role `starter-dev-ec2-ssm-role`. Once approved, obtain temporary credentials:

```powershell
aws sts assume-role --role-arn arn:aws:iam::<account>:role/starter-dev-ec2-ssm-role --role-session-name dev-session
```

Export the returned credentials (or load them into your profile tool of choice). All remaining commands assume you have those credentials active.

## 2. Locate the shared EC2 instance

The platform team will share the instance ID. If you need to look it up yourself, list running instances by tag:

```powershell
aws ec2 describe-instances `
  --region ap-southeast-2 `
  --filters Name=tag:Name,Values=starter-dev-ec2 Name=instance-state-name,Values=running `
  --query "Reservations[].Instances[].InstanceId" --output text
```

Record the instance ID - you will use it for both the SSM session and the port-forward commands.

## 3. Connect with AWS Systems Manager (SSM)

Start an interactive shell on the instance:

```powershell
aws ssm start-session --region ap-southeast-2 --target <EC2_INSTANCE_ID>
```

Within the session, switch to the application folder and verify the smoke test runs with the preinstalled toolchain:

```bash
cd /home/ec2-user/AWSSmokeTest/apps/hello-service-java
mvn -q -DskipTests package
java -cp target/hello-service-0.1.0.jar App
```

Expected output confirms connectivity to Postgres, Redis, RabbitMQ, and S3 (look for `Postgres insert OK`, `Redis counter value`, `RabbitMQ publish OK`, and `S3 put/get OK`). Exit the session when finished.

## 4. Test port forwarding from your laptop

Port forwarding lets you reach private services from your workstation without exposing them to the internet.

1. In three separate terminals, run the helper scripts and leave them running:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\ssm_port_forward_db.ps1 -InstanceId <EC2_INSTANCE_ID> -RemoteHost <RDS_ENDPOINT>  # optional override
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\ssm_port_forward_redis.ps1 -InstanceId <EC2_INSTANCE_ID> -RemoteHost <REDIS_ENDPOINT>  # optional override
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\ssm_port_forward_rabbitmq.ps1 -InstanceId <EC2_INSTANCE_ID> -RemoteHost <RABBITMQ_HOST>  # optional override
   ```
   (Hosts come from `terraform output -raw rds_endpoint`, `redis_endpoint`, and `mq_endpoint`. Override `-LocalPort` if you need a different local port.)

2. Confirm each tunnel is accepting connections from your machine:
   ```powershell
   Test-NetConnection 127.0.0.1 -Port 5432
   Test-NetConnection 127.0.0.1 -Port 6379
   Test-NetConnection 127.0.0.1 -Port 5671
   ```
   Successful tests show `TcpTestSucceeded : True`.

3. When you are done, stop the sessions with `Ctrl+C` in each terminal.

## 5. Troubleshooting and support

- `aws ssm describe-instance-information --region ap-southeast-2` checks that the SSM agent is healthy.
- `aws ssm list-command-invocations --region ap-southeast-2 --command-id <id> --details` retrieves output from recent SSM commands if debugging with the platform team.
- `aws ec2 get-console-output --latest --instance-id <EC2_INSTANCE_ID>` surfaces the latest boot logs.

If you encounter issues connecting or the smoke test output differs from expectations, capture any error text and contact the platform team rather than attempting Terraform or configuration changes yourself.

