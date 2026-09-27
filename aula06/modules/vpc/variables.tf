variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto (usado em tags e nomes)"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "subnets" {
  description = "Mapa de subnets a serem criadas. Cada entrada define cidr, az e type (public|private)."
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))
}
