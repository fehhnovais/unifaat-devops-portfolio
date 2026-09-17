# Aula 05 — Infraestrutura Completa TechNova (VPC + RDS + EC2 + Estado Remoto)

## Arquitetura

```
                          ┌─────────────────────────────────────────────┐
                          │              VPC 10.0.0.0/16                │
                          │                                             │
                          │  ┌──────────────────────────────────────┐  │
                          │  │  Sub-rede Pública  10.0.1.0/24       │  │
                          │  │  AZ: us-east-1a                      │  │
                          │  │                                      │  │
Internet ──── IGW ────────┼──┤  ┌──────────┐                       │  │
                          │  │  │  EC2     │ t2.micro               │  │
                          │  │  │  (psql)  │                       │  │
                          │  │  └────┬─────┘                       │  │
                          │  └───────┼──────────────────────────────┘  │
                          │          │ porta 5432 (SG reference)        │
                          │  ┌───────┼──────────────────────────────┐  │
                          │  │  Sub-redes Privadas                  │  │
                          │  │  10.0.10.0/24 (us-east-1a)          │  │
                          │  │  10.0.11.0/24 (us-east-1b)          │  │
                          │  │                                      │  │
                          │  │  ┌──────────────────────────────┐   │  │
                          │  │  │  RDS PostgreSQL 15            │   │  │
                          │  │  │  db.t3.micro  (privado)       │   │  │
                          │  │  └──────────────────────────────┘   │  │
                          │  └──────────────────────────────────────┘  │
                          └─────────────────────────────────────────────┘

Estado Remoto: S3 (technova-terraform-state-<ACCOUNT_ID>) + DynamoDB (technova-terraform-locks)
```

## Estrutura de Arquivos

```
aula-05/
├── backend/                     ← Passo 1: cria S3 + DynamoDB para o estado
│   ├── .gitignore
│   ├── main.tf                  # S3 (versioning + encryption + block_public) + DynamoDB
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf               # Exibe o bloco backend para copiar
│   └── terraform.tfvars.example
│
├── .gitignore                   ← Ignora *.tfstate, *.tfvars, *.pem, .terraform/
├── providers.tf                 # Provider AWS + bloco backend S3 (comentado inicialmente)
├── variables.tf                 # Todas as variáveis (db_password marcada como sensitive)
├── network.tf                   # VPC, sub-redes, IGW, route tables, DB subnet group
├── security_groups.tf           # SG do EC2 (22, 3000) e SG do RDS (5432 ← EC2 SG)
├── ec2.tf                       # EC2 t2.micro + user_data (instala psql + script de teste)
├── rds.tf                       # RDS PostgreSQL 15, db.t3.micro, sub-redes privadas
├── outputs.tf                   # IP EC2, endpoint RDS, string de conexão, próximos passos
├── terraform.tfvars.example     # Template de variáveis (copiar para terraform.tfvars)
└── README.md
```

---

## Pré-requisitos

- [Terraform >= 1.0](https://developer.hashicorp.com/terraform/downloads)
- [AWS CLI configurado](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Par de chaves SSH criado na AWS

### Criar par de chaves SSH

```powershell
# Criar par de chaves na AWS e salvar localmente
aws ec2 create-key-pair --key-name technova-key --query 'KeyMaterial' --output text > technova-key.pem

# Ajustar permissões (Windows/PowerShell)
icacls technova-key.pem /inheritance:r
icacls technova-key.pem /grant:r "$($env:USERNAME):(R)"
```

---

## Fluxo de Deploy

### Passo 1 — Criar infraestrutura de backend (S3 + DynamoDB)

```powershell
cd aula-05/backend

# Criar terraform.tfvars com seu Account ID
Copy-Item terraform.tfvars.example terraform.tfvars
# Editar: bucket_suffix = "SEU-ACCOUNT-ID"
# Para descobrir: aws sts get-caller-identity --query Account --output text

terraform init
terraform apply
```

Após o apply, copie o output `backend_config_snippet` — você vai precisar dele no próximo passo.

### Passo 2 — Configurar as variáveis do projeto principal

```powershell
cd ..   # voltar para aula-05/

Copy-Item terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars:
#   - db_password: use uma senha forte
#   - ec2_key_name: nome do par de chaves criado
#   - state_bucket_name: nome do bucket criado no passo 1
```

### Passo 3 — Deploy inicial (estado local)

```powershell
terraform init
terraform plan
terraform apply
```

Anote os outputs — especialmente `ec2_public_ip` e `rds_address`.

### Passo 4 — Migrar para estado remoto

```powershell
# 1. Abrir providers.tf e descomentar o bloco backend "s3" {...}
#    Preencher com os valores do output backend_config_snippet do passo 1

# 2. Reinicializar com migração de estado
terraform init -migrate-state
# Digite 'yes' quando solicitado

# 3. Verificar que o estado está no S3
aws s3 ls s3://technova-terraform-state-<ACCOUNT_ID>/aula05/
```

---

## Testando a Infraestrutura

### Conectar ao EC2

```powershell
# Obter o comando SSH pronto nos outputs
terraform output ec2_ssh_command

# Conectar
ssh -i technova-key.pem ec2-user@<EC2_PUBLIC_IP>
```

### Testar conexão EC2 → RDS

```bash
# Dentro do EC2 — usar o script criado pelo user_data
./test-db.sh

# OU manualmente
export PGPASSWORD='SuaSenha'
psql -h <RDS_ADDRESS> -U dbadmin -d technovadb -c "SELECT version();"
```

### Criar tabela e dados de teste

```sql
-- Dentro do psql
CREATE TABLE IF NOT EXISTS orders (
    id         SERIAL PRIMARY KEY,
    product    VARCHAR(100) NOT NULL,
    quantity   INT          NOT NULL,
    created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders (product, quantity) VALUES
    ('Laptop',  5),
    ('Mouse',  20),
    ('Teclado', 15);

SELECT * FROM orders;
```

### Verificar plano limpo

```powershell
terraform plan
# Esperado: "No changes. Your infrastructure matches the configuration."
```

---

## Evidências para o PR

| # | Evidência | Comando |
|---|-----------|---------|
| 1 | Estado no S3 | `aws s3 ls s3://<BUCKET>/aula05/` |
| 2 | Conexão EC2→RDS | `psql -h <HOST> -U dbadmin -d technovadb -c "SELECT version();"` |
| 3 | Dados persistentes | `SELECT * FROM orders;` |
| 4 | Plano limpo | `terraform plan` → "No changes" |

---

## Destruição (OBRIGATÓRIA após capturar evidências)

```powershell
# 1. Destruir infraestrutura principal
cd aula-05/
terraform destroy

# 2. Esvaziar bucket S3 (incluindo versões)
$bucket = "technova-terraform-state-<ACCOUNT_ID>"
aws s3 rm s3://$bucket --recursive
# Para versões antigas:
aws s3api delete-objects --bucket $bucket `
  --delete (aws s3api list-object-versions --bucket $bucket `
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' `
    --output json)

# 3. Destruir infraestrutura de backend
cd backend/
terraform destroy

# 4. Confirmar no console AWS que nenhum recurso restou
```

> ⚠️ Recursos não destruídos geram custos na conta AWS!

---

## Segurança

- ✅ RDS em sub-redes privadas (sem acesso público)
- ✅ SG do RDS aceita porta 5432 **apenas** do SG do EC2 (bônus já implementado)
- ✅ Criptografia habilitada no RDS (`storage_encrypted = true`)
- ✅ Criptografia habilitada no S3 (AES-256)
- ✅ Versionamento habilitado no bucket S3
- ✅ Acesso público bloqueado no bucket S3 (todos os 4 flags = true)
- ✅ Variável `db_password` marcada como `sensitive = true`
- ✅ `.gitignore` cobre `*.tfstate`, `*.tfvars`, `*.pem`, `.terraform/`

---

## Bônus Implementados

- [x] **SG do RDS referencia o SG do EC2** (em vez de CIDR da VPC)
- [x] **User data automatizado** — instala psql + cria script de teste + `.pgpass`
- [ ] Terraform Workspaces (dev/prod)
- [ ] IAM Instance Profile para EC2
