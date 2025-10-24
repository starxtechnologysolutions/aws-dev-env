terraform {
  # Local state for now (we can move to S3 backend later)
  backend "local" {}
}

locals {
  project = var.project
  env     = var.env

  common_tags = {
    Project = local.project
    Env     = local.env
    ManagedBy = "Terraform"
  }
}

# Helpful data sources (often used in other files)
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}