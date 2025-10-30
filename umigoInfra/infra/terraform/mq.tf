resource "aws_mq_broker" "rabbit" {
  broker_name                = "${var.project}-${var.env}-rabbit"
  engine_type                = "RabbitMQ"
  engine_version             = "3.13"
  auto_minor_version_upgrade = true
  host_instance_type         = "mq.t3.micro"
  deployment_mode            = "SINGLE_INSTANCE"
  publicly_accessible        = false

  user {
    username = var.rabbit_user
    password = var.rabbit_pass
  }

  logs {
    general = true
  }

  subnet_ids      = [element(sort([for s in aws_subnet.private : s.id]), 0)]
  security_groups = [aws_security_group.mq_sg.id]

  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

output "rabbit_amqp_endpoint" {
  value = aws_mq_broker.rabbit.instances[0].endpoints[0]
}