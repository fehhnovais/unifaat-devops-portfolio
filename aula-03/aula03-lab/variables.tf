variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente (development, staging, production)"
  type        = string
  default     = "development"
}

variable "bucket_suffix" {
  description = "Sufixo único para o nome do bucket (seu nome ou RA)"
  type        = string
}