param([Parameter(Mandatory=$true)][string]$InstanceId)
aws ssm start-session `
  --target $InstanceId `
  --document-name AWS-StartPortForwardingSession `
  --parameters '{"portNumber":["5671"],"localPortNumber":["5671"]}'
