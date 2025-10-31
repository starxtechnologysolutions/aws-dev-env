variable "project" {
  type    = string
  default = "umigo"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "rabbit_user" {
  type    = string
  default = "app"
}

variable "rabbit_pass" {
  type      = string
  sensitive = true
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user that hosts the backend repository."
}

variable "github_repo" {
  type        = string
  description = "Name of the GitHub repository that contains the backend source."
}

variable "github_branch" {
  type        = string
  default     = "master"
  description = "Default branch used by the backend deployment pipeline."
}

variable "codestar_connection_arn" {
  type        = string
  description = "ARN of the pre-created CodeStar Connections GitHub connection."
}
