output "vpc_id"             { value = aws_vpc.main.id }
output "public_subnet_ids"  { value = [aws_subnet.public.id] }
output "private_subnet_ids" { value = values(aws_subnet.private)[*].id }

output "ec2_instance_id"    { value = aws_instance.app.id }
output "ec2_public_ip"      { value = aws_instance.app.public_ip }
output "ec2_iam_role"       { value = aws_iam_role.ec2_ssm_role.name }

output "rds_endpoint"       { value = aws_db_instance.postgres.address }
output "rds_port"           { value = aws_db_instance.postgres.port }
output "rds_db_name"        { value = aws_db_instance.postgres.db_name }
output "rds_username"       { value = aws_db_instance.postgres.username }
output "rds_master_secret_arn" { value = aws_db_instance.postgres.master_user_secret[0].secret_arn }

output "redis_endpoint"     { value = aws_elasticache_cluster.redis.cache_nodes[0].address }
output "redis_port"         { value = aws_elasticache_cluster.redis.cache_nodes[0].port }

output "mq_endpoint"        { value = aws_mq_broker.rabbit.instances[0].endpoints[0] }

output "s3_bucket_name"     { value = aws_s3_bucket.app_bucket.bucket }
output "ec2_instance_security_group_id" { value = aws_security_group.ec2_sg.id }

