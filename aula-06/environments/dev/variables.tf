variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "technova"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "subnets" {
  description = "Mapa de subnets (cidr, az, type)"
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))
}

variable "key_name" {
  description = "Nome do key pair SSH (opcional)"
  type        = string
  default     = null
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_username" {
  description = "Usuário master do banco"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Senha master do banco (sensível)"
  type        = string
  sensitive   = true
}
