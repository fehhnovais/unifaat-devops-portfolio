terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Tags obrigatórias aplicadas automaticamente a TODOS os recursos que
  # suportam tagging (users, policies, roles, instance profiles).
  # Groups do IAM não suportam tags — ver comentário em groups.tf.
  default_tags {
    tags = {
      Project    = var.project_name
      ManagedBy  = "Terraform"
      Aluno      = var.aluno
      RA         = var.ra
      Disciplina = var.disciplina
      Aula       = var.aula
    }
  }
}
