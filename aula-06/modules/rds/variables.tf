variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_username" {
  description = "Usuário master do banco de dados"
  type        = string
}

variable "db_password" {
  description = "Senha master do banco de dados"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Lista de IDs das subnets privadas para o DB Subnet Group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Lista de IDs de Security Groups para o RDS"
  type        = list(string)
}

variable "instance_class" {
  description = "Classe da instância RDS (Free Tier: db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "15"
}

variable "allocated_storage" {
  description = "Armazenamento alocado em GB"
  type        = number
  default     = 20
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}
