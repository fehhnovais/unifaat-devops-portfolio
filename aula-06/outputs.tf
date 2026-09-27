output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.vpc.private_subnet_ids
}

output "api_sg_id" {
  description = "ID do Security Group da API"
  value       = module.api_sg.sg_id
}

output "rds_sg_id" {
  description = "ID do Security Group do RDS"
  value       = module.rds_sg.sg_id
}

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = module.api_server.instance_id
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = module.api_server.public_ip
}

output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = module.database.db_endpoint
}

output "rds_database_name" {
  description = "Nome do banco de dados"
  value       = module.database.db_name
}
