resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project}-${var.env}-redis-subnets"
  subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id         = "${var.project}-${var.env}-redis"
  engine             = "redis"
  node_type          = "cache.t4g.micro"
  num_cache_nodes    = 1
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis_sg.id]
  port               = 6379
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

output "redis_host" { value = aws_elasticache_cluster.redis.cache_nodes[0].address }
output "redis_port" { value = aws_elasticache_cluster.redis.cache_nodes[0].port }
