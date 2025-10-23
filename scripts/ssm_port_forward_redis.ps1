param([Parameter(Mandatory=$true)][string]$InstanceId)
aws ssm start-session `
  --target $InstanceId `
  --document-name AWS-StartPortForwardingSession `
  --parameters '{"portNumber":["6379"],"localPortNumber":["6379"]}'
