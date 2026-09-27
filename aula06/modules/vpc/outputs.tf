output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block da VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Lista de IDs das subnets públicas"
  value       = [for k, v in aws_subnet.this : v.id if var.subnets[k].type == "public"]
}

output "private_subnet_ids" {
  description = "Lista de IDs das subnets privadas"
  value       = [for k, v in aws_subnet.this : v.id if var.subnets[k].type == "private"]
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.this.id
}
