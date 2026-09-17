terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 — descomente e preencha APÓS rodar o terraform apply na pasta backend/
  # Os valores estão nos outputs do backend (terraform output -raw backend_config_snippet)
  #
  # backend "s3" {
  #   bucket         = "technova-terraform-state-SEU-ACCOUNT-ID"
  #   key            = "aula05/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "technova-terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "TechNova"
      Aula      = "05"
      ManagedBy = "Terraform"
    }
  }
}
