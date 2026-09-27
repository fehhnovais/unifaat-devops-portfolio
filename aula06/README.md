# Aula 06 — Biblioteca de Módulos Terraform | TechNova

Biblioteca de módulos Terraform reutilizáveis da TechNova. Com os mesmos 4 módulos
(VPC, Security Group, EC2, RDS) é possível provisionar ambientes completos —
**dev** e **staging** — apenas variando os valores de entrada.

- **Aluno:** Fernanda Rosa Novais Tavares
- **RA:** 4025109
- **Tema:** Terraform Modules

## Visão Geral

A ideia é padronizar a infraestrutura: em vez de reescrever VPC, SG, EC2 e RDS
para cada ambiente, cada um vira um **módulo** parametrizável. O root module de
cada ambiente apenas **compõe** esses módulos, ligando o output de um ao input do
outro (ex.: o `vpc_id` da VPC alimenta os Security Groups; os IDs de subnet
alimentam o EC2 e o RDS).

## Arquitetura — Dependências entre Módulos

```
                   ┌───────────────┐
                   │  módulo VPC   │
                   │ (for_each de  │
                   │   subnets)    │
                   └───────┬───────┘
             vpc_id ┌──────┴───────┐ subnet_ids
                    ▼              ▼
          ┌──────────────┐   (public/private)
          │ módulo SG    │        │
          │ (api + rds)  │        │
          └──────┬───────┘        │
            sg_id│                │
        ┌────────┴────────┐       │
        ▼                 ▼       ▼
 ┌─────────────┐    ┌─────────────────┐
 │ módulo EC2  │    │   módulo RDS     │
 │ subnet pub. │    │ subnets privadas │
 │ + api_sg    │    │ + rds_sg         │
 └─────────────┘    └─────────────────┘
```

## Estrutura de Diretórios

```
aula-06/
├── README.md
├── .gitignore
├── environments/
│   ├── dev/          # VPC 10.0.0.0/16, db technova_dev
│   │   ├── main.tf   # compõe os 4 módulos
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── terraform.tfvars
│   └── staging/      # VPC 10.1.0.0/16, db technova_staging
│       └── (mesma estrutura do dev)
└── modules/
    ├── vpc/
    ├── security-group/
    ├── ec2/
    └── rds/
```

## Módulos Disponíveis

### Módulo VPC

**Descrição:** Cria VPC completa com subnets dinâmicas via `for_each`, Internet
Gateway e route table pública associada às subnets públicas.

**Inputs:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `vpc_cidr` | string | Sim | CIDR block da VPC |
| `project_name` | string | Sim | Nome do projeto |
| `environment` | string | Sim | Ambiente |
| `subnets` | map(object) | Sim | Mapa de subnets `{cidr, az, type}` |

**Outputs:** `vpc_id`, `vpc_cidr`, `public_subnet_ids`, `private_subnet_ids`, `internet_gateway_id`

**Exemplo:**
```hcl
module "vpc" {
  source       = "../../modules/vpc"
  vpc_cidr     = "10.0.0.0/16"
  project_name = "technova"
  environment  = "dev"
  subnets = {
    "public-1"  = { cidr = "10.0.1.0/24", az = "us-east-1a", type = "public" }
    "private-1" = { cidr = "10.0.3.0/24", az = "us-east-1a", type = "private" }
  }
}
```

### Módulo Security Group

**Descrição:** Security Group genérico. Recebe as regras de entrada como lista de
objetos (via `dynamic "ingress"`) e sempre aplica egress liberado.

**Inputs:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Sim | Nome do SG |
| `vpc_id` | string | Sim | ID da VPC |
| `ingress_rules` | list(object) | Não | Regras `{description, from_port, to_port, protocol, cidr_blocks}` |
| `environment` | string | Sim | Ambiente |
| `project_name` | string | Sim | Nome do projeto |

**Outputs:** `sg_id`, `sg_arn`, `sg_name`

**Exemplo:**
```hcl
module "api_sg" {
  source       = "../../modules/security-group"
  name         = "api-sg"
  vpc_id       = module.vpc.vpc_id
  project_name = "technova"
  environment  = "dev"
  ingress_rules = [
    { description = "SSH", from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]
}
```

### Módulo EC2

**Descrição:** Cria uma instância EC2 (default t2.micro) com AMI, subnet e SGs
configuráveis. Aceita `user_data` opcional.

**Inputs:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `instance_name` | string | Sim | Nome da instância |
| `instance_type` | string | Não | Tipo (default `t2.micro`) |
| `ami_id` | string | Sim | ID da AMI |
| `subnet_id` | string | Sim | ID da subnet |
| `security_group_ids` | list(string) | Sim | Lista de SG IDs |
| `key_name` | string | Não | Key pair SSH |
| `user_data` | string | Não | Script de bootstrap |
| `environment` / `project_name` | string | Sim | Ambiente / projeto |

**Outputs:** `instance_id`, `public_ip`, `private_ip`, `availability_zone`

**Exemplo:**
```hcl
module "api_server" {
  source             = "../../modules/ec2"
  instance_name      = "api"
  ami_id             = data.aws_ami.amazon_linux_2023.id
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.api_sg.sg_id]
  project_name       = "technova"
  environment        = "dev"
}
```

### Módulo RDS

**Descrição:** Cria um DB Subnet Group com as subnets privadas e uma instância
RDS PostgreSQL (default db.t3.micro), com configurações de desenvolvimento.

**Inputs:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `db_name` | string | Sim | Nome do database |
| `db_username` | string | Sim | Usuário master |
| `db_password` | string (sensitive) | Sim | Senha master |
| `subnet_ids` | list(string) | Sim | Subnets privadas |
| `security_group_ids` | list(string) | Sim | SG IDs do RDS |
| `instance_class` | string | Não | Classe (default `db.t3.micro`) |
| `engine_version` | string | Não | Versão PostgreSQL (default `15`) |
| `allocated_storage` | number | Não | GB (default `20`) |
| `environment` / `project_name` | string | Sim | Ambiente / projeto |

**Outputs:** `db_endpoint`, `db_address`, `db_name`, `db_port`, `db_subnet_group_name`

**Exemplo:**
```hcl
module "database" {
  source             = "../../modules/rds"
  db_name            = "technova_dev"
  db_username        = "dbadmin"
  db_password        = var.db_password
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.rds_sg.sg_id]
  project_name       = "technova"
  environment        = "dev"
}
```

## Composição entre Módulos

O `main.tf` de cada ambiente demonstra a composição (output de um módulo → input de outro):

| Origem | Output | Destino | Input |
|--------|--------|---------|-------|
| VPC | `vpc_id` | api_sg / rds_sg | `vpc_id` |
| VPC | `public_subnet_ids[0]` | EC2 | `subnet_id` |
| VPC | `private_subnet_ids` | RDS | `subnet_ids` |
| api_sg | `sg_id` | EC2 | `security_group_ids` |
| rds_sg | `sg_id` | RDS | `security_group_ids` |

## Diferenças entre Ambientes

| Aspecto | Dev | Staging |
|---------|-----|---------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Subnets públicas | 10.0.1.0/24, 10.0.2.0/24 | 10.1.1.0/24, 10.1.2.0/24 |
| Subnets privadas | 10.0.3.0/24, 10.0.4.0/24 | 10.1.3.0/24, 10.1.4.0/24 |
| DB Name | technova_dev | technova_staging |
| Naming | technova-dev-* | technova-staging-* |

## Como Usar

### Pré-requisitos
- [Terraform >= 1.0](https://developer.hashicorp.com/terraform/downloads)
- AWS CLI configurado (ou credenciais do AWS Academy ativas)
- Key pair SSH criado na AWS (se for usar acesso SSH ao EC2)

### Validar / provisionar um ambiente

```bash
# Ambiente dev
cd aula-06/environments/dev
terraform init
terraform validate
terraform plan
# terraform apply    # opcional — destrua depois

# Ambiente staging
cd ../staging
terraform init
terraform validate
terraform plan
```

> ⚠️ Se rodar `terraform apply`, execute `terraform destroy` ao final para não
> consumir recursos do Learner Lab. Dois ambientes ao mesmo tempo dobram o consumo.

### Criar um novo ambiente

Copie a pasta `environments/dev/`, ajuste o `terraform.tfvars` (CIDR, nomes, db) e
os defaults de `environment` — os módulos permanecem os mesmos.

## Boas Práticas Aplicadas

- Tags em todos os recursos: `Name`, `Environment`, `Project`, `ManagedBy`
- `db_password` marcada como `sensitive`
- Variáveis com `description` e `type`; outputs com `description`
- `.gitignore` cobre `.terraform/`, `*.tfstate`, `terraform.tfvars`, `*.pem`
- Módulos desacoplados e reutilizáveis (nenhum valor hardcoded específico de ambiente)
