# =============================================================================
# BACKEND INFRASTRUCTURE - S3 + DynamoDB para Estado Remoto do Terraform
# =============================================================================
# Execute este módulo PRIMEIRO antes do projeto principal.
# Após apply, copie os outputs para o bloco backend do providers.tf principal.
# =============================================================================

locals {
  bucket_name = "${var.project_name}-terraform-state-${var.bucket_suffix}"
  table_name  = "${var.project_name}-terraform-locks"
}

# -----------------------------------------------------------------------------
# S3 Bucket para armazenar o terraform.tfstate
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name

  # Impede destruição acidental do bucket com o estado
  lifecycle {
    prevent_destroy = false # true em produção real
  }

  tags = {
    Name = local.bucket_name
  }
}

# Habilitar versionamento (obrigatório para estado remoto)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia do lado do servidor (SSE-S3 / AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Bloquear todo acesso público ao bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Política de ciclo de vida: manter apenas as últimas 10 versões do estado
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days           = 90
      newer_noncurrent_versions = 10
    }
  }
}

# -----------------------------------------------------------------------------
# DynamoDB para locking do estado (evita apply simultâneo)
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = local.table_name
  }
}
