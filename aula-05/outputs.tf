# =============================================================================
# OUTPUTS — Informações úteis após o apply
# =============================================================================

# --- VPC ---
output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da sub-rede pública (EC2)"
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "IDs das sub-redes privadas (RDS)"
  value       = aws_subnet.private[*].id
}

# --- EC2 ---
output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.app.public_ip
}

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.app.id
}

output "ec2_ssh_command" {
  description = "Comando SSH para conectar ao EC2"
  value       = "ssh -i ${var.ec2_key_name}.pem ec2-user@${aws_instance.app.public_ip}"
}

# --- RDS ---
output "rds_endpoint" {
  description = "Endpoint completo do RDS (host:porta)"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Endereço do RDS (apenas host, sem porta)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.main.db_name
}

output "rds_connection_string" {
  description = "Comando psql para conectar ao RDS a partir do EC2"
  value       = "psql -h ${aws_db_instance.main.address} -U ${var.db_username} -d ${var.db_name}"
  sensitive   = true
}

# --- Estado Remoto (informativo) ---
output "remote_state_bucket" {
  description = "Bucket S3 onde o estado Terraform está armazenado"
  value       = var.state_bucket_name != "" ? var.state_bucket_name : "Backend local — configure o bloco backend em providers.tf"
}

output "remote_state_dynamodb_table" {
  description = "Tabela DynamoDB para locking do estado"
  value       = var.state_dynamodb_table
}

# --- Instruções pós-deploy ---
output "next_steps" {
  description = "Passos para testar a infraestrutura"
  value       = <<-EOT

    ==============================================
    PRÓXIMOS PASSOS
    ==============================================
    1. Conectar ao EC2:
       ssh -i ${var.ec2_key_name}.pem ec2-user@${aws_instance.app.public_ip}

    2. Testar conexão EC2 → RDS (dentro do EC2):
       ./test-db.sh
       OU manualmente:
       psql -h ${aws_db_instance.main.address} -U ${var.db_username} -d ${var.db_name}

    3. Verificar estado remoto (após configurar backend):
       aws s3 ls s3://${var.state_bucket_name}/aula05/
    ==============================================
  EOT
}
