resource "aws_secretsmanager_secret" "rabbit_app" { name = "dev/rabbitmq/app" }
resource "aws_secretsmanager_secret_version" "rabbit_app_value" {
  secret_id     = aws_secretsmanager_secret.rabbit_app.id
  secret_string = jsonencode({ username = var.rabbit_user, password = random_password.rabbit.result })
}

resource "random_password" "rabbit" {
  length           = 24
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  special          = true
}
