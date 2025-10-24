resource "aws_mq_broker" "rabbit" {
  broker_name        = "${var.project}-${var.env}-rabbit"
  engine_type        = "RabbitMQ"
  engine_version     = "3.13.2"
  host_instance_type = "mq.t3.micro"
  deployment_mode    = "SINGLE_INSTANCE"
  publicly_accessible = false

  user {
    username = var.rabbit_user
    password = random_password.rabbit.result
  }

  logs { general = true }

  subnet_ids = values(aws_subnet.private)[*].id
  security_groups = [aws_security_group.mq_sg.id]

  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

