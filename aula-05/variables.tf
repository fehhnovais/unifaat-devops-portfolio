# =============================================================================
# VARIÁVEIS GERAIS
# =============================================================================

variable "aws_region" {
  description = "Região AWS para os recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado como prefixo em todos os recursos)"
  type        = string
  default     = "technova"
}

# =============================================================================
# VARIÁVEIS DE REDE
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block da sub-rede pública (EC2)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks das 2 sub-redes privadas (RDS) em AZs diferentes"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Zonas de disponibilidade (pelo menos 2 para o DB Subnet Group)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# =============================================================================
# VARIÁVEIS EC2
# =============================================================================

variable "ec2_instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ec2_key_name" {
  description = "Nome do par de chaves SSH criado na AWS"
  type        = string
  default     = "technova-key"
}

variable "allowed_ssh_cidr" {
  description = "CIDR permitido para acesso SSH (restrinja ao seu IP em produção)"
  type        = string
  default     = "0.0.0.0/0"
}

# =============================================================================
# VARIÁVEIS RDS
# =============================================================================

variable "db_name" {
  description = "Nome do banco de dados PostgreSQL"
  type        = string
  default     = "technovadb"
}

variable "db_username" {
  description = "Usuário master do banco de dados"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Senha do banco de dados (sensível — não commitar)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe da instância RDS (Free Tier: db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento alocado em GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "15"
}

# =============================================================================
# VARIÁVEIS ESTADO REMOTO (usadas nos outputs para referência)
# =============================================================================

variable "state_bucket_name" {
  description = "Nome do bucket S3 criado pelo backend/ (para exibir nos outputs)"
  type        = string
  default     = ""
}

variable "state_dynamodb_table" {
  description = "Nome da tabela DynamoDB criada pelo backend/ (para exibir nos outputs)"
  type        = string
  default     = "technova-terraform-locks"
}
