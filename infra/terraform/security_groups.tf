resource "aws_security_group" "ec2_sg" {
  name   = "${var.project}-${var.env}-ec2-sg"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_security_group" "db_sg" {
  name   = "${var.project}-${var.env}-db-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  egress  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_security_group" "redis_sg" {
  name   = "${var.project}-${var.env}-redis-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  egress  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}

resource "aws_security_group" "mq_sg" {
  name   = "${var.project}-${var.env}-mq-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5671
    to_port         = 5671
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  # Uncomment if enabling mgmt UI via SSM-only port-forward
  # ingress {
  #   from_port       = 15672
  #   to_port         = 15672
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.ec2_sg.id]
  # }
  egress  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Env = var.env, Project = "Starter", Owner = "Roy" }
}
