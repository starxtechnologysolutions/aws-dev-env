# AWS Dev: EC2 + Postgres (RDS) + Redis + Amazon MQ (RabbitMQ) + S3 (Java smoke)

## Prereqs
- AWS CLI v2 configured (MFA/SSO or keys)
- Terraform v1.6+
- Java 17+ & Maven

## Docs
- [Backend <-> Infra Sync](docs/backend-sync.md)

## Backend Bootstrap
- Windows: run scripts/bootstrap-backend.ps1 to launch SSM tunnels, fetch secrets, generate .env.bootstrap, optionally seed the DB and start Spring Boot. Use -RunBackend to launch the app and keep the port-forward windows open.
- macOS/Linux: run scripts/bootstrap-backend.sh (requires bash, aws, terraform, python, optional tmux). Add --run-backend or --skip-port-forward as needed.


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
- Console â†?EC2 â†?Connect â†?**Session Manager**
- Or CLI: `aws ssm start-session --target <INSTANCE_ID>`

## Optional: Port-forward locally (DB/Redis/MQ)
Use the helpers under /scripts (remote endpoints are resolved from Terraform outputs):
```powershell
# database -> localhost:15432
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ssm_port_forward_db.ps1 -InstanceId <INSTANCE_ID>
# redis -> localhost:16379
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ssm_port_forward_redis.ps1 -InstanceId <INSTANCE_ID>
# rabbitmq -> localhost:15671
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ssm_port_forward_rabbitmq.ps1 -InstanceId <INSTANCE_ID>
```
On macOS/Linux use the bash bootstrap helper or run `scripts/bootstrap-backend.sh --skip-seed` to start all tunnels.

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










