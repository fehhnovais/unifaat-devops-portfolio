output "db_endpoint" {
  description = "Endpoint do RDS (host:porta)"
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Endereço do RDS (apenas host)"
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.this.db_name
}

output "db_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.this.port
}

output "db_subnet_group_name" {
  description = "Nome do DB Subnet Group"
  value       = aws_db_subnet_group.this.name
}
