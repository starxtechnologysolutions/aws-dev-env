resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project}-${var.env}-redis-subnets"
  subnet_ids = values(aws_subnet.private)[*].id
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

