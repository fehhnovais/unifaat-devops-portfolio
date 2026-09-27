variable "instance_name" {
  description = "Nome da instância EC2 (usado na tag Name)"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID da AMI a ser usada"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde a instância será criada"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de IDs de Security Groups a anexar à instância"
  type        = list(string)
}

variable "key_name" {
  description = "Nome do key pair para acesso SSH"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Script user_data opcional para bootstrap da instância"
  type        = string
  default     = null
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}
