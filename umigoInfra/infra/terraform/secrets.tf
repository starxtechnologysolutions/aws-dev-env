resource "aws_secretsmanager_secret" "rds_app" { name = "dev/rds/app" }
resource "aws_secretsmanager_secret_version" "rds_app_value" {
  secret_id     = aws_secretsmanager_secret.rds_app.id
  secret_string = jsonencode({ username = var.db_username, password = var.db_password })
}

resource "aws_secretsmanager_secret" "rabbit_app" { name = "dev/rabbitmq/app" }
resource "aws_secretsmanager_secret_version" "rabbit_app_value" {
  secret_id     = aws_secretsmanager_secret.rabbit_app.id
  secret_string = jsonencode({ username = var.rabbit_user, password = var.rabbit_pass })
}
