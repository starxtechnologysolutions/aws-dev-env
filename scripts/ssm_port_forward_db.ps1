param([Parameter(Mandatory=$true)][string]$InstanceId)
aws ssm start-session `
  --target $InstanceId `
  --document-name AWS-StartPortForwardingSession `
  --parameters '{"portNumber":["5432"],"localPortNumber":["5432"]}'
