variable "project" {
	type = string
}

variable "env" {
	type = string
}

variable "region"  {
	type    = string
	default = "ap-southeast-2"
}

variable "aws_profile" {
	type    = string
	default = "default"
}

# VPC
variable "vpc_cidr" {
	type    = string
	default = "10.20.0.0/16"
}

variable "public_subnet_cidrs"  {
	type    = list(string)
	default = ["10.20.0.0/24"]
}

variable "private_subnet_cidrs" {
	type    = list(string)
	default = ["10.20.10.0/24","10.20.11.0/24"]
}

# EC2
variable "ec2_instance_type" {
	type    = string
	default = "t3.micro"
}

variable "ec2_key_name"      {
	type    = string
	default = null
} # optional if using SSM only

# RDS
variable "rds_engine_version" {
	type    = string
	default = "16.4"
}

variable "rds_instance_class" {
	type    = string
	default = "db.t3.micro"
}

variable "rds_db_name"        {
	type    = string
	default = "appdb"
}

variable "rds_username"       {
	type    = string
	default = "appuser"
}


# Redis
variable "redis_node_type" {
	type    = string
	default = "cache.t4g.micro"
}

# MQ (RabbitMQ)
variable "mq_instance_type" {
	type    = string
	default = "mq.t3.micro"
}

variable "rabbit_user" {
	type = string
}


# S3
variable "s3_bucket_suffix" {
	type    = string
	default = "app-bucket"
}

