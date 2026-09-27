# =============================================================================
# MÓDULO RDS — DB Subnet Group + instância PostgreSQL
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# DB Subnet Group — agrupa as subnets privadas (exige >= 2 AZs)
resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${local.name_prefix}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Instância RDS PostgreSQL
resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids

  multi_az            = false
  publicly_accessible = false

  # Configurações sensatas para desenvolvimento
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "${local.name_prefix}-postgresql"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
