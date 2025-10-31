output "region" {
  value = var.aws_region
}

output "backend_ssm_parameters" {
  value = {
    SPRING_DATASOURCE_URL = aws_ssm_parameter.backend_datasource_url.name
    SPRING_REDIS_HOST     = aws_ssm_parameter.backend_redis_host.name
    SPRING_REDIS_PORT     = aws_ssm_parameter.backend_redis_port.name
  }
}

output "app_bucket_name" {
  value = aws_s3_bucket.app_bucket.bucket
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.artifact_bucket.bucket
}

output "backend_codebuild_project" {
  value = aws_codebuild_project.backend.name
}

output "backend_codepipeline_name" {
  value = aws_codepipeline.backend.name
}

output "backend_codedeploy_app" {
  value = aws_codedeploy_app.backend.name
}

output "deployment_alerts_topic_arn" {
  value = aws_sns_topic.deployment_alerts.arn
}
