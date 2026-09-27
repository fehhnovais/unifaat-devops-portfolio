# =============================================================================
# ROOT MODULE (aula-06) — composição da biblioteca de módulos na raiz
# O CI valida a partir da raiz. Este main.tf compõe os 4 módulos (VPC + SG +
# EC2 + RDS) equivalente ao ambiente dev. Para dev/staging separados, veja
# environments/dev e environments/staging.
# =============================================================================

# AMI mais recente do Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── VPC ──────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
  subnets      = var.subnets
}

# ── Security Group da API ────────────────────────────────────────────────────
# Composição: recebe vpc_id do módulo VPC
module "api_sg" {
  source = "./modules/security-group"

  name         = "api-sg"
  vpc_id       = module.vpc.vpc_id # ← Composição!
  project_name = var.project_name
  environment  = var.environment

  ingress_rules = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "API Node.js"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# ── Security Group do RDS ────────────────────────────────────────────────────
# PostgreSQL apenas de dentro da VPC
module "rds_sg" {
  source = "./modules/security-group"

  name         = "rds-sg"
  vpc_id       = module.vpc.vpc_id # ← Composição!
  project_name = var.project_name
  environment  = var.environment

  ingress_rules = [
    {
      description = "PostgreSQL da VPC interna"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  ]
}

# ── EC2 (API Server) ─────────────────────────────────────────────────────────
# Composição: subnet pública da VPC + SG da API
module "api_server" {
  source = "./modules/ec2"

  instance_name      = "api"
  ami_id             = data.aws_ami.amazon_linux_2023.id
  instance_type      = "t2.micro"
  subnet_id          = module.vpc.public_subnet_ids[0] # ← Composição!
  security_group_ids = [module.api_sg.sg_id]           # ← Composição!
  key_name           = var.key_name
  project_name       = var.project_name
  environment        = var.environment
}

# ── RDS (Database) ───────────────────────────────────────────────────────────
# Composição: subnets privadas da VPC + SG do RDS
module "database" {
  source = "./modules/rds"

  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  subnet_ids         = module.vpc.private_subnet_ids # ← Composição!
  security_group_ids = [module.rds_sg.sg_id]         # ← Composição!
  instance_class     = "db.t3.micro"
  project_name       = var.project_name
  environment        = var.environment
}
