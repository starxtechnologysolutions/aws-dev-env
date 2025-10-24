param(
  [Parameter(Mandatory=$true)][string]$InstanceId,
  [string]$Region = 'ap-southeast-2',
  [switch]$FromTfOutputs,
  [string]$RdsSecretArn,
  [string]$S3BucketName,
  [string]$RedisHost,
  [string]$RedisPort = '6379',
  [string]$RabbitHost,
  [string]$RabbitPort = '5671',
  [string]$ServiceName
)

$ErrorActionPreference = 'Stop'

function Resolve-TerraformExe {
  $tf = (Get-Command terraform -ErrorAction SilentlyContinue).Source
  if (-not [string]::IsNullOrWhiteSpace($tf)) { return $tf }
  $candidates = @(
    'C:\\Program Files\\Terraform\\terraform.exe',
    'C:\\Program Files\\HashiCorp\\Terraform\\terraform.exe'
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  throw 'terraform executable not found. Install Terraform or add it to PATH.'
}

function Get-TfOutputRaw($name) {
  $terraformExe = Resolve-TerraformExe
  $tfDir = Resolve-Path "$PSScriptRoot/../infra/terraform"
  Push-Location $tfDir
  try {
    $val = & $terraformExe output -raw $name 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($val)) { return $null }
    return $val.Trim()
  } finally { Pop-Location }
}

if ($FromTfOutputs) {
  if (-not $RdsSecretArn) { $RdsSecretArn = Get-TfOutputRaw 'rds_master_secret_arn' }
  if (-not $S3BucketName) { $S3BucketName = Get-TfOutputRaw 's3_bucket_name' }
  if (-not $RedisHost)    { $RedisHost    = Get-TfOutputRaw 'redis_endpoint' }
  if (-not $RabbitHost)   {
    $mqEndpoint = Get-TfOutputRaw 'mq_endpoint'
    if ($mqEndpoint) {
      # Strip scheme and port if present
      $tmp = $mqEndpoint -replace '^[a-zA-Z]+://',''
      $tmp = $tmp -replace ':[0-9]+$',''
      $RabbitHost = $tmp
    }
  }
}

# Basic validation
$missing = @()
if (-not $RdsSecretArn) { $missing += 'RdsSecretArn' }
if (-not $S3BucketName) { $missing += 'S3BucketName' }
if (-not $RedisHost)    { $missing += 'RedisHost' }
if (-not $RabbitHost)   { $missing += 'RabbitHost' }
if ($missing.Count -gt 0) {
  throw "Missing values: $($missing -join ', '). Provide -FromTfOutputs or pass them explicitly."
}

Write-Host "Wiring environment on instance $InstanceId"
Write-Host "  AWS_REGION=$Region"
Write-Host "  RDS_SECRET_ID=$RdsSecretArn"
Write-Host "  S3_BUCKET_NAME=$S3BucketName"
Write-Host "  REDIS_HOST=${RedisHost}:${RedisPort}"
Write-Host "  RABBITMQ_HOST=${RabbitHost}:${RabbitPort}"

# Build env file and optional systemd drop-in via heredoc
$envLines = @(
  ('export AWS_REGION={0}'       -f $Region),
  ('export RDS_SECRET_ID={0}'    -f $RdsSecretArn),
  ('export S3_BUCKET_NAME={0}'   -f $S3BucketName),
  ('export REDIS_HOST={0}'       -f $RedisHost),
  ('export REDIS_PORT={0}'       -f $RedisPort),
  ('export RABBITMQ_HOST={0}'    -f $RabbitHost),
  ('export RABBITMQ_PORT={0}'    -f $RabbitPort)
)
$envContent = ($envLines -join "`n")
$cmds = @()

$heredoc = @"
sudo tee /etc/hello-service.env >/dev/null <<'EOF'
$envContent
EOF
"@
$cmds += $heredoc
$cmds += 'sudo chmod 0644 /etc/hello-service.env'
$cmds += 'echo ". /etc/hello-service.env" | sudo tee /etc/profile.d/hello-service.sh >/dev/null'

if ($ServiceName) {
  $dropInDir = "/etc/systemd/system/$ServiceName.d"
  $dropInContent = "[Service]`nEnvironmentFile=/etc/hello-service.env"
  $dropin = @"
sudo mkdir -p $dropInDir
sudo tee $dropInDir/10-env.conf >/dev/null <<'EOF'
$dropInContent
EOF
"@
  $cmds += $dropin
  $cmds += 'sudo systemctl daemon-reload'
  $cmds += ("sudo systemctl try-restart {0} || true" -f $ServiceName)
}
# Build payload and write to a temp file to avoid PowerShell quoting issues
$payload = @{
  InstanceIds  = @($InstanceId)
  DocumentName = 'AWS-RunShellScript'
  Comment      = 'Wire hello-service env vars'
  Parameters   = @{ commands = $cmds }
}
$payloadJson = $payload | ConvertTo-Json -Compress -Depth 8
$tmpPath = [System.IO.Path]::GetTempFileName()
$keep = $env:SSM_DEBUG_KEEP -eq '1'
if ($keep) { $tmpPath = Join-Path $PSScriptRoot 'ssm_payload.json' }
if ($keep) { Write-Host ("Debug: payload path: {0}" -f $tmpPath)  }
try {
  # Ensure UTF8 without BOM for AWS CLI compatibility
  [System.IO.File]::WriteAllText($tmpPath, $payloadJson, (New-Object System.Text.UTF8Encoding $false))

  $cmdId = (& aws 'ssm' 'send-command' '--region' $Region '--cli-input-json' ("file://$tmpPath") --query 'Command.CommandId' --output text)
  if (-not $cmdId) { throw 'Failed to invoke SSM send-command' }
} finally {
  if ((-not $keep) -and (Test-Path $tmpPath)) { Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue }
}

Write-Host "Sent SSM command: $cmdId"

# Wait for completion
$state = 'InProgress'
while ($state -eq 'InProgress' -or $state -eq 'Pending') {
  Start-Sleep -Seconds 2
  $state = (aws ssm list-command-invocations --region $Region --command-id $cmdId --details --query 'CommandInvocations[0].Status' --output text)
}

Write-Host "SSM command status: $state"
$log = (aws ssm list-command-invocations --region $Region --command-id $cmdId --details --query 'CommandInvocations[0].CommandPlugins[0].Output' --output text)
if ($log) { Write-Host $log }

if ($state -ne 'Success') { throw "SSM command failed with status $state" }

Write-Host "Environment wired successfully on $InstanceId. Re-login to pick up /etc/profile.d/hello-service.sh."













