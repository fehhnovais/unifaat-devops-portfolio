output "state_bucket_name" {
  description = "Nome do bucket S3 para armazenar o estado Terraform"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para locking"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "backend_config_snippet" {
  description = "Copie este bloco para o providers.tf do projeto principal"
  value       = <<-EOT

    backend "s3" {
      bucket         = "${aws_s3_bucket.terraform_state.id}"
      key            = "aula05/terraform.tfstate"
      region         = "${var.aws_region}"
      encrypt        = true
      dynamodb_table = "${aws_dynamodb_table.terraform_locks.id}"
    }

  EOT
}
