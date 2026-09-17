variable "aws_region" {
  description = "Região AWS para os recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado como prefixo nos recursos)"
  type        = string
  default     = "technova"
}

variable "bucket_suffix" {
  description = "Sufixo único para o bucket S3 (use o Account ID ou um valor aleatório)"
  type        = string
  # Sem default — deve ser fornecido em terraform.tfvars
  # Exemplo: bucket_suffix = "123456789012"  (Account ID da AWS)
}
