# Smoke Test Quick Run

Follow these steps from a blank workstation to prove the managed environment is healthy. Complete the prerequisites once, then repeat only the run section when you need to verify the stack.

## Prerequisites

1. **Install AWS CLI v2** - download from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html and confirm with `aws --version`.
2. **Install the AWS Session Manager Plugin** - follow https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html and confirm with `session-manager-plugin --version`.
3. **Configure baseline credentials** - authenticate with the identity that is allowed to assume the shared role:
   - SSO: `aws configure sso` (then `aws sso login --profile <base-profile>`).
   - IAM access keys: `aws configure --profile <base-profile>` and supply key/secret/region.
4. **Assume the shared role and export the temporary keys**:
   - **Windows PowerShell**
     ```powershell
     $session = aws sts assume-role `
       --profile <base-profile> `
       --role-arn arn:aws:iam::<account>:role/starter-dev-ec2-ssm-role `
       --role-session-name dev-session | ConvertFrom-Json
     $Env:AWS_ACCESS_KEY_ID     = $session.Credentials.AccessKeyId
     $Env:AWS_SECRET_ACCESS_KEY = $session.Credentials.SecretAccessKey
     $Env:AWS_SESSION_TOKEN     = $session.Credentials.SessionToken
     ```
   - **macOS/Linux shell** (requires `jq`; install via `brew install jq` or your package manager)
     ```bash
     session_json=$(aws sts assume-role \
       --profile <base-profile> \
       --role-arn arn:aws:iam::<account>:role/starter-dev-ec2-ssm-role \
       --role-session-name dev-session)
     export AWS_ACCESS_KEY_ID=$(echo "$session_json" | jq -r .Credentials.AccessKeyId)
     export AWS_SECRET_ACCESS_KEY=$(echo "$session_json" | jq -r .Credentials.SecretAccessKey)
     export AWS_SESSION_TOKEN=$(echo "$session_json" | jq -r .Credentials.SessionToken)
     ```
   (Alternatively, store the values in a dedicated profile with `aws configure set ... --profile dev-session` and set `AWS_PROFILE=dev-session`.)
5. **Optional tooling** - install Git if you want to browse the repo locally.

Verify the role switch once: `aws sts get-caller-identity` should show an ARN of the form `arn:aws:sts::<account>:assumed-role/starter-dev-ec2-ssm-role/<session-name>`.

## Run the smoke

1. **Port forward with SSM**
   - **Windows PowerShell**
     ```powershell
     powershell -NoProfile -ExecutionPolicy Bypass `
       -File scripts\ssm_port_forward_db.ps1 `
       -InstanceId i-03801fee7b905eb4f
     powershell -NoProfile -ExecutionPolicy Bypass `
       -File scripts\ssm_port_forward_redis.ps1 `
       -InstanceId i-03801fee7b905eb4f
     powershell -NoProfile -ExecutionPolicy Bypass `
       -File scripts\ssm_port_forward_rabbitmq.ps1 `
       -InstanceId i-03801fee7b905eb4f
     ```
   - **macOS/Linux** (PowerShell Core required: `brew install powershell` or `sudo apt install powershell`)
     ```bash
     pwsh -NoProfile -ExecutionPolicy Bypass \
       -File scripts/ssm_port_forward_db.ps1 \
       -InstanceId i-03801fee7b905eb4f
     pwsh -NoProfile -ExecutionPolicy Bypass \
       -File scripts/ssm_port_forward_redis.ps1 \
       -InstanceId i-03801fee7b905eb4f
     pwsh -NoProfile -ExecutionPolicy Bypass \
       -File scripts/ssm_port_forward_rabbitmq.ps1 \
       -InstanceId i-03801fee7b905eb4f
     ```
     > No PowerShell Core? You can call the AWS CLI directly, e.g.:
     > ```bash
     > aws ssm start-session \
     >   --region ap-southeast-2 \
     >   --target i-03801fee7b905eb4f \
     >   --document-name AWS-StartPortForwardingSessionToRemoteHost \
     >   --parameters host=<REMOTE_HOST>,portNumber=<REMOTE_PORT>,localPortNumber=<LOCAL_PORT>
     > ```
   Scripts auto-resolve endpoint hosts via `terraform output -raw ...`; provide `-RemoteHost` only if you need to point at a different host. Leave each window running.

2. **Open a shell on the EC2 instance**
   ```powershell
   aws ssm start-session --region ap-southeast-2 --target i-03801fee7b905eb4f
   sudo su - ec2-user
   ```
   (Same command works in macOS/Linux shells.)

3. **Run the smoke app**
   ```bash
   source /etc/hello-service.env
   cd /home/ec2-user/aws-dev-env/apps/hello-service-java
   mvn -q exec:java -Dexec.mainClass=App
   ```

4. **Confirm success**
   - Expect to see:
     - `Postgres insert OK: ...`
     - `Redis counter: ...`
     - `RabbitMQ publish OK`
     - `S3 put OK` and `S3 get OK`
   - Any failure pinpoints which service needs attention.

5. **Optional: Close out**
   - Exit the EC2 shell: `exit` (twice if still inside the `ec2-user` shell).
   - Stop the port-forward windows with `Ctrl+C`.

Terraform outputs (`terraform output -raw rds_endpoint`, etc.) provide the remote hosts if you need to override `-RemoteHost`. The platform team refreshes `/etc/hello-service.env` whenever infrastructure changes; no Terraform or additional scripts are required for routine checks.