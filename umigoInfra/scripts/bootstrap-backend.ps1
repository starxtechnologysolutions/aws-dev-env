param(
  [string]$InstanceId,
  [string]$Region = 'ap-southeast-2',
  [string]$Env = 'dev',
  [string]$BackendPath,
  [string]$Profile,
  [switch]$SkipPortForward,
  [switch]$SkipSeed,
  [switch]$RunBackend,
  [switch]$NoEnvFile
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Info($message) { Write-Host "[INFO] $message" -ForegroundColor Cyan }
function Write-Warn($message) { Write-Host "[WARN] $message" -ForegroundColor Yellow }
function Write-ErrorLine($message) { Write-Host "[ERROR] $message" -ForegroundColor Red }

function Ensure-Command([string]$name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "Required command '$name' was not found in PATH." }
  return $cmd
}

function Resolve-TerraformExe {
  $cmd = Get-Command terraform -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $candidates = @(
    'C:\Program Files\Terraform\terraform.exe',
    'C:\Program Files\HashiCorp\Terraform\terraform.exe'
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { return $c }
  }
  throw "Terraform executable not found. Install Terraform or add it to PATH."
}

function Get-TerraformOutput([string]$name, [switch]$Raw) {
  $terraformExe = Resolve-TerraformExe
  $tfDir = Resolve-Path "$scriptDir/../infra/terraform"
  Push-Location $tfDir
  try {
    $args = @('output')
    if ($Raw) { $args += '-raw' }
    $args += $name
    $result = & $terraformExe @args 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    if ($Raw) { return $result.Trim() }
    return $result
  } finally {
    Pop-Location
  }
}

function Start-PortForward($scriptName, $params) {
  $psArgs = @('-NoExit', '-File', "$scriptDir/$scriptName")
  foreach ($kv in $params.GetEnumerator()) {
    if ($null -ne $kv.Value) {
      $psArgs += @($('-' + $kv.Key), $kv.Value)
    }
  }
  Write-Info "Launching port forward: $scriptName"
  Start-Process -FilePath 'powershell.exe' -ArgumentList $psArgs
}

Ensure-Command 'aws' | Out-Null
Ensure-Command 'powershell' | Out-Null

if (-not $InstanceId) {
  $InstanceId = Get-TerraformOutput 'ec2_instance_id' -Raw
  if (-not $InstanceId) { throw 'Unable to determine EC2 instance id. Pass -InstanceId explicitly.' }
}

if (-not $BackendPath) {
  $workspaceRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).ProviderPath
  $candidatePaths = @(
    (Join-Path $workspaceRoot 'Umigo/umigoCrmBackend'),
    (Join-Path $workspaceRoot 'umigoCrmBackend')
  )
  foreach ($c in $candidatePaths) {
    if (Test-Path $c) { $BackendPath = (Resolve-Path $c).Path; break }
  }
}

$backendAvailable = $false
if (-not [string]::IsNullOrWhiteSpace($BackendPath) -and (Test-Path $BackendPath)) {
  $BackendPath = (Resolve-Path $BackendPath).Path
  $backendAvailable = $true
} else {
  Write-Warn "Backend path not found. Use -BackendPath to point to the umigoCrmBackend project."
  $BackendPath = $null
}

$awsArgs = @()
if ($Profile) { $awsArgs += @('--profile', $Profile) }
$awsArgs += @('--region', $Region)

$localPorts = [ordered]@{
  Db     = '15432'
  Redis  = '16379'
  Rabbit = '15671'
}

if (-not $SkipPortForward) {
  Start-PortForward 'ssm_port_forward_db.ps1' ([ordered]@{ InstanceId = $InstanceId; Region = $Region; LocalPort = $localPorts.Db })
  Start-PortForward 'ssm_port_forward_redis.ps1' ([ordered]@{ InstanceId = $InstanceId; Region = $Region; LocalPort = $localPorts.Redis })
  Start-PortForward 'ssm_port_forward_rabbitmq.ps1' ([ordered]@{ InstanceId = $InstanceId; Region = $Region; LocalPort = $localPorts.Rabbit })
  Write-Info 'Ensure the port-forward windows stay open while working.'
} else {
  Write-Info 'Skipping port forwarding as requested.'
}

Write-Info 'Fetching Secrets Manager values...'

function Get-Secret([string]$name) {
  $cmd = @('secretsmanager','get-secret-value','--secret-id',$name,'--query','SecretString','--output','text')
  $result = aws @awsArgs @cmd 2>$null
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($result)) {
    throw "Failed to read secret '$name'. Ensure your AWS credentials permit secretsmanager:GetSecretValue."
  }
  return $result | ConvertFrom-Json
}

$dbSecretName     = "$Env/rds/app"
$rabbitSecretName = "$Env/rabbitmq/app"

try {
  $dbSecret = Get-Secret $dbSecretName
} catch {
  Write-ErrorLine $_.Exception.Message
  throw
}

try {
  $rabbitSecret = Get-Secret $rabbitSecretName
} catch {
  Write-ErrorLine $_.Exception.Message
  throw
}

$redisHost = Get-TerraformOutput 'redis_host' -Raw
if (-not $redisHost) { $redisHost = 'localhost' }
$s3Bucket = Get-TerraformOutput 's3_bucket_name' -Raw

$dbName = if ($dbSecret.PSObject.Properties.Name -contains 'dbname' -and $dbSecret.dbname) { $dbSecret.dbname } else { 'appdb' }

$envValues = [ordered]@{
  SPRING_PROFILES_ACTIVE = 'dev'
  SPRING_DATASOURCE_URL  = "jdbc:postgresql://localhost:$($localPorts.Db)/$dbName"
  SPRING_DATASOURCE_USERNAME = $dbSecret.username
  SPRING_DATASOURCE_PASSWORD = $dbSecret.password
  SPRING_REDIS_HOST = 'localhost'
  SPRING_REDIS_PORT = $localPorts.Redis
  SPRING_RABBITMQ_HOST = 'localhost'
  SPRING_RABBITMQ_PORT = $localPorts.Rabbit
  SPRING_RABBITMQ_USERNAME = $rabbitSecret.username
  SPRING_RABBITMQ_PASSWORD = $rabbitSecret.password
  UMIGO_FIREBASE_CONFIG_PATH = './config/serviceAccountKey.json'
  AWS_REGION = $Region
  S3_BUCKET_NAME = $s3Bucket
}

if (-not $NoEnvFile -and $backendAvailable) {
  $envFilePath = Join-Path $BackendPath '.env.bootstrap'
  $lines = $envValues.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }
  Set-Content -Path $envFilePath -Value $lines
  Write-Info "Wrote environment template $envFilePath"
} else {
  Write-Info 'Skipping env file generation (missing backend path or -NoEnvFile supplied).'
}

if (-not $SkipSeed -and $backendAvailable) {
  try {
    $psql = Get-Command psql -ErrorAction Stop
    $schemaPath = Join-Path $BackendPath 'src/main/resources/schema.sql'
    if (Test-Path $schemaPath) {
      Write-Info 'Seeding database schema via psql...'
      $env:PGPASSWORD = $dbSecret.password
      & $psql.Source @('-h','localhost','-p',$localPorts.Db,'-U',$dbSecret.username,'-d',$dbName,'-f',$schemaPath)
      if ($LASTEXITCODE -eq 0) {
        Write-Info 'Schema applied successfully.'
      } else {
        Write-Warn 'psql reported a non-zero exit code. Check output above.'
      }
      Remove-Item Env:PGPASSWORD
    } else {
      Write-Warn "Schema file not found at $schemaPath. Skipping database seed."
    }
  } catch {
    Write-Warn "psql not available or failed to run. Install PostgreSQL client if you want automatic seeding."
  }
} else {
  Write-Info 'Skipping database seed.'
}

if ($RunBackend -and $backendAvailable) {
  $mvnw = Join-Path $BackendPath 'mvnw'
  if (-not (Test-Path $mvnw)) { $mvnw = Join-Path $BackendPath 'mvnw.cmd' }
  if (-not (Test-Path $mvnw)) {
    Write-Warn 'Could not find mvnw or mvnw.cmd in backend path. Skipping backend launch.'
  } else {
    Write-Info 'Launching backend with Spring Boot...'
    foreach ($kv in $envValues.GetEnumerator()) { Set-Item -Path "Env:$($kv.Key)" -Value $kv.Value }
    Push-Location $BackendPath
    try {
      if ($mvnw.EndsWith('.cmd')) {
        & $mvnw spring-boot:run
      } else {
        & $mvnw spring-boot:run
      }
    } finally {
      Pop-Location
    }
  }
} else {
  Write-Info 'Backend not started (use -RunBackend to launch spring-boot:run).'
}

Write-Info 'Bootstrap complete. Keep the port-forward sessions running while you develop.'





