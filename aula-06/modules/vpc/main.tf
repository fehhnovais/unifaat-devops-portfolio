# =============================================================================
# MÓDULO VPC — VPC + subnets dinâmicas (for_each) + IGW + Route Tables
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Separa as subnets por tipo para facilitar route tables e outputs
  public_subnets  = { for k, v in var.subnets : k => v if v.type == "public" }
  private_subnets = { for k, v in var.subnets : k => v if v.type == "private" }
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.name_prefix}-vpc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Subnets — criadas dinamicamente a partir do mapa var.subnets
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.type == "public"

  tags = {
    Name        = "${local.name_prefix}-${each.key}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Type        = each.value.type
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-igw"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Route Table pública — rota default para o IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${local.name_prefix}-public-rt"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Associa a route table pública a cada subnet pública
resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}
