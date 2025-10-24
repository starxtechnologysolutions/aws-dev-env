data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  user_data = <<-EOF
    #!/bin/bash
    dnf -y update
    dnf -y install amazon-ssm-agent git docker java-17-openjdk maven
    systemctl enable --now amazon-ssm-agent
    systemctl enable --now docker
    usermod -aG docker ec2-user

    # Write environment for app runtime
    cat > /etc/hello-service.env <<EOT
export AWS_REGION="${var.region}"
export RDS_SECRET_ID="${aws_db_instance.postgres.master_user_secret[0].secret_arn}"
export S3_BUCKET_NAME="${aws_s3_bucket.app_bucket.bucket}"
export REDIS_HOST="${aws_elasticache_cluster.redis.cache_nodes[0].address}"
export REDIS_PORT="6379"
export RABBITMQ_HOST="${aws_mq_broker.rabbit.instances[0].endpoints[0]}"
export RABBITMQ_PORT="5671"
EOT
    chmod 0644 /etc/hello-service.env
    echo 'source /etc/hello-service.env' > /etc/profile.d/hello-service.sh
  EOF
  tags = { Name = "${var.project}-${var.env}-ec2", Env = var.env, Project = "Starter", Owner = "Roy" }
}

