variable "project"     { type = string  default = "starter" }
variable "env"         { type = string  default = "dev" }
variable "aws_region"  { type = string  default = "ap-southeast-2" }
variable "vpc_cidr"    { type = string  default = "10.20.0.0/16" }
variable "public_cidr" { type = string  default = "10.20.0.0/24" }
variable "private_cidrs" { type = list(string) default = ["10.20.1.0/24","10.20.2.0/24"] }

variable "db_username" { type = string default = "appuser" }
variable "db_password" { type = string sensitive = true }
variable "db_name"     { type = string default = "appdb" }

variable "rabbit_user" { type = string default = "app" }
variable "rabbit_pass" { type = string sensitive = true }
