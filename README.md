# AWS Dev: EC2 + Postgres (RDS) + Redis + Amazon MQ (RabbitMQ) + S3 (Java smoke)

## Prereqs
- AWS CLI v2 configured (MFA/SSO or keys)
- Terraform v1.6+
- Java 17+ & Maven

## One-time
```sh
cd infra/terraform
terraform init
terraform plan -out tfplan
terraform apply tfplan
terraform output
```
Secrets to create (values already set by terraform module if you pass variables):
- `dev/rds/app` (username/password)
- `dev/rabbitmq/app` (username/password)

## Connect to EC2
- Console → EC2 → Connect → **Session Manager**
- Or CLI: `aws ssm start-session --target <INSTANCE_ID>`

## Optional: Port-forward locally (DB/Redis/MQ)
See scripts in `/scripts`.

## Build & run Java smoke (on EC2 or locally with SSM tunnels)
```sh
cd apps/hello-service-java
mvn -q -DskipTests package
java -cp target/hello-service-0.1.0.jar App
```
Expected output:
- Postgres insert OK
- Redis counter value
- RabbitMQ publish OK
- S3 put/get OK

## Destroy
```sh
cd infra/terraform && terraform destroy -auto-approve
```
