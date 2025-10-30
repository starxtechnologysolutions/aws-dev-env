resource "aws_ssm_parameter" "backend_datasource_url" {
  name  = "/${var.env}/backend/SPRING_DATASOURCE_URL"
  type  = "String"
  value = "jdbc:postgresql://${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${var.db_name}?sslmode=require"
}

resource "aws_ssm_parameter" "backend_redis_host" {
  name  = "/${var.env}/backend/SPRING_REDIS_HOST"
  type  = "String"
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

resource "aws_ssm_parameter" "backend_redis_port" {
  name  = "/${var.env}/backend/SPRING_REDIS_PORT"
  type  = "String"
  value = tostring(aws_elasticache_cluster.redis.cache_nodes[0].port)
}
