resource "aws_db_subnet_group" "db" {
  name       = "${var.project}-${var.env}-db-subnets"
  subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.project}-${var.env}-pg"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  allocated_storage      = 20
  storage_type           = "gp3"
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

output "postgres_host" { value = aws_db_instance.postgres.address }
output "postgres_port" { value = aws_db_instance.postgres.port }
output "postgres_db"   { value = aws_db_instance.postgres.db_name }
output "postgres_user" { value = aws_db_instance.postgres.username }
