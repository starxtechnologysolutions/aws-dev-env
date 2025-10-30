output "region" { value = var.aws_region }

output "backend_ssm_parameters" {
  value = {
    SPRING_DATASOURCE_URL = aws_ssm_parameter.backend_datasource_url.name
    SPRING_REDIS_HOST     = aws_ssm_parameter.backend_redis_host.name
    SPRING_REDIS_PORT     = aws_ssm_parameter.backend_redis_port.name
  }
}
