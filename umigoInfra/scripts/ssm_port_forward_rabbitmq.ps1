param(
  [Parameter(Mandatory=$true)][string]$InstanceId,
  [string]$Region = 'ap-southeast-2',
  [string]$RemoteHost,
  [string]$LocalPort = '15671',
  [string]$RemotePort
)

function Resolve-TerraformExe {
  $tf = (Get-Command terraform -ErrorAction SilentlyContinue).Source
  if ($tf) { return $tf }
  $candidates = @(
    'C:\Program Files\Terraform\terraform.exe',
    'C:\Program Files\HashiCorp\Terraform\terraform.exe'
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { return $c }
  }
  return $null
}

function Get-TfOutputRaw([string]$name) {
  $terraformExe = Resolve-TerraformExe
  if (-not $terraformExe) { return $null }
  $tfDir = Resolve-Path "$PSScriptRoot/../infra/terraform"
  Push-Location $tfDir
  try {
    $val = & $terraformExe output -raw $name 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($val)) { return $null }
    return $val.Trim()
  } finally {
    Pop-Location
  }
}

if (-not $RemoteHost) {
  $RemoteHost = Get-TfOutputRaw 'rabbit_amqp_endpoint'
  if ($RemoteHost -and $RemoteHost -match '^amqps://([^:]+):(\d+)') {
    $RemoteHost = $matches[1]
    if (-not $RemotePort) { $RemotePort = $matches[2] }
  }
}

if (-not $RemoteHost) {
  throw "Remote host not provided and Terraform output 'rabbit_amqp_endpoint' could not be resolved. Pass -RemoteHost."
}

if (-not $RemotePort) {
  $RemotePort = Get-TfOutputRaw 'rabbit_amqp_port'
}

if (-not $RemotePort) {
  $RemotePort = '5671'
}

$paramObject = [ordered]@{
  host            = @($RemoteHost)
  portNumber      = @($RemotePort)
  localPortNumber = @($LocalPort)
}
$paramJson = $paramObject | ConvertTo-Json -Compress
$tempFile = [System.IO.Path]::GetTempFileName()
Set-Content -LiteralPath $tempFile -Value $paramJson -NoNewline

$cliArgs = @(
  'ssm','start-session',
  '--region',$Region,
  '--target',$InstanceId,
  '--document-name','AWS-StartPortForwardingSessionToRemoteHost',
  '--parameters',"file://$tempFile"
)

Write-Host ('Forwarding localhost:{0} -> {1}:{2} via instance {3}' -f $LocalPort, $RemoteHost, $RemotePort, $InstanceId)
try {
  aws @cliArgs
} finally {
  Remove-Item -LiteralPath $tempFile -ErrorAction SilentlyContinue
}
