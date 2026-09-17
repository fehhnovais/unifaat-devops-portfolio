# =============================================================================
# RDS — PostgreSQL 15 nas sub-redes privadas
# =============================================================================

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class

  # Armazenamento
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true

  # Credenciais
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Rede e segurança
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Alta disponibilidade — false para laboratório (Free Tier)
  multi_az = false

  # Manutenção e backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Logs no CloudWatch
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Laboratório: sem snapshot final ao destruir
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-postgresql"
  }
}
