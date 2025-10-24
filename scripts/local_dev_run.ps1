# Sets environment variables for local dev using Terraform outputs and runs the Java smoke test.
# Requires: Terraform, AWS CLI (for port forwarding scripts), Java 17 + Maven installed locally.

param(
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

function Resolve-TerraformExe {
  $tf = (Get-Command terraform -ErrorAction SilentlyContinue).Source
  if (-not [string]::IsNullOrWhiteSpace($tf)) { return $tf }
  $candidates = @(
    'C:\Program Files\Terraform\terraform.exe',
    'C:\Program Files\HashiCorp\Terraform\terraform.exe'
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  throw 'terraform executable not found. Install Terraform or add it to PATH.'
}

# Move to terraform dir to read outputs
$tfDir = Resolve-Path "$PSScriptRoot/../infra/terraform"
$terraformExe = Resolve-TerraformExe
Push-Location $tfDir

function Get-TfOutputRaw($name) {
  $val = & $terraformExe output -raw $name 2>$null
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($val)) { return $null }
  return $val.Trim()
}

# Gather outputs (best-effort)
$rdsSecretArn   = Get-TfOutputRaw 'rds_master_secret_arn'
$s3Bucket       = Get-TfOutputRaw 's3_bucket_name'
$redisEndpoint  = Get-TfOutputRaw 'redis_endpoint'
$rabbitEndpoint = Get-TfOutputRaw 'mq_endpoint'
$ec2Id          = Get-TfOutputRaw 'ec2_instance_id'

Pop-Location

# Set environment for local port-forward use
if (-not $env:AWS_REGION) { $env:AWS_REGION = 'ap-southeast-2' }
if ($rdsSecretArn) { $env:RDS_SECRET_ID = $rdsSecretArn }
if ($s3Bucket)     { $env:S3_BUCKET_NAME = $s3Bucket }

# Localhost endpoints via SSM port forwarding
$env:POSTGRES_HOST = '127.0.0.1'
$env:POSTGRES_PORT = '5432'
$env:REDIS_HOST    = '127.0.0.1'
$env:REDIS_PORT    = '6379'
$env:RABBITMQ_HOST = '127.0.0.1'
$env:RABBITMQ_PORT = '5671'

Write-Host "Using RDS secret: $($env:RDS_SECRET_ID)"
Write-Host "Using S3 bucket: $($env:S3_BUCKET_NAME)"
if ($ec2Id) {
  Write-Host "EC2 instance id: $ec2Id"
  Write-Host "Run port-forward in separate terminals:"
  Write-Host "  scripts\\ssm_port_forward_db.ps1 -InstanceId $ec2Id"
  Write-Host "  scripts\\ssm_port_forward_redis.ps1 -InstanceId $ec2Id"
  Write-Host "  scripts\\ssm_port_forward_rabbitmq.ps1 -InstanceId $ec2Id"
} else {
  Write-Host "EC2 instance id not found in outputs. Ensure terraform apply has created the instance."
}

# Build/run app
if (-not $SkipBuild) {
  & "$PSScriptRoot/build_run_java.ps1"
} else {
  Push-Location "$PSScriptRoot/../apps/hello-service-java"
  java -cp target/hello-service-0.1.0.jar App
  Pop-Location
}
