# Variáveis reutilizáveis do projeto IAM da TechNova

variable "aws_region" {
  description = "Região AWS onde os recursos IAM serão gerenciados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado em tags e prefixos)"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente do projeto"
  type        = string
  default     = "development"
}

variable "aluno" {
  description = "Nome do aluno responsável pela entrega"
  type        = string
  default     = "Fernanda Rosa Novais Tavares"
}

variable "ra" {
  description = "RA (registro acadêmico) do aluno"
  type        = string
  default     = "4025109"
}

variable "disciplina" {
  description = "Disciplina e período"
  type        = string
  default     = "DevOps - UniFAAT 2026-2"
}

variable "aula" {
  description = "Número da aula"
  type        = string
  default     = "03"
}
