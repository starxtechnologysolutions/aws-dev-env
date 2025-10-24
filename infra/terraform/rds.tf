resource "aws_db_subnet_group" "db" {
  name       = "${var.project}-${var.env}-db-subnets"
  subnet_ids = values(aws_subnet.private)[*].id
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.project}-${var.env}-pg"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  db_name                = var.rds_db_name
  username               = var.rds_username
  manage_master_user_password = true
  allocated_storage      = 20
  storage_type           = "gp3"
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

