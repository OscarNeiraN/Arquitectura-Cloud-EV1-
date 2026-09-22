terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  # Project, Environment y ManagedBy en todos los recursos AWS que crea Terraform
  default_tags {
    tags = local.common_tags
  }
}
