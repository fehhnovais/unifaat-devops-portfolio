# Infraestrutura TechNova — Aula 04

VPC + EC2 Multi-AZ provisionada com Terraform, preparada para alta disponibilidade
e pronta para receber um Load Balancer no futuro.

- **Aluno:** Fernanda Rosa Novais Tavares
- **RA:** 4025109
- **Tema:** Terraform — VPC + EC2 Multi-AZ

## Diagrama da Arquitetura

```
                              Internet
                                 │
                                 ▼
                       ┌───────────────────┐
                       │ Internet Gateway  │
                       └─────────┬─────────┘
                                 │
                   ┌─────────────┴──────────────┐
                   │   Route Table Pública      │
                   │   0.0.0.0/0 → IGW          │
                   └──────┬──────────────┬──────┘
                          │              │
      VPC 10.0.0.0/16     │              │
   ┌──────────────────────┼──────────────┼───────────────────────┐
   │                      │              │                       │
   │   AZ us-east-1a      │              │   AZ us-east-1b       │
   │  ┌───────────────────▼──┐        ┌──▼────────────────────┐  │
   │  │ Subnet Pública 1     │        │ Subnet Pública 2      │  │
   │  │ 10.0.1.0/24          │        │ 10.0.3.0/24           │  │
   │  │                      │        │                       │  │
   │  │  ┌────────────────┐  │        │                       │  │
   │  │  │  EC2 t2.micro  │  │        │                       │  │
   │  │  │  API :3000     │  │        │                       │  │
   │  │  │  + S3 RO Role  │  │        │                       │  │
   │  │  └────────────────┘  │        │                       │  │
   │  └──────────────────────┘        └───────────────────────┘  │
   │  ┌──────────────────────┐        ┌───────────────────────┐  │
   │  │ Subnet Privada 1     │        │ Subnet Privada 2      │  │
   │  │ 10.0.2.0/24          │        │ 10.0.4.0/24           │  │
   │  │ (sem rota p/ IGW)    │        │ (futuro: RDS Multi-AZ)│  │
   │  └──────────────────────┘        └───────────────────────┘  │
   └─────────────────────────────────────────────────────────────┘

Security Groups:
  api-sg → SSH (22) e API (3000) de 0.0.0.0/0
  db-sg  → PostgreSQL (5432) apenas de 10.0.0.0/16 (interno)
```

## Como Usar

### Pré-requisitos

- [Terraform >= 1.0](https://developer.hashicorp.com/terraform/downloads)
- [AWS CLI configurado](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (ou credenciais do AWS Academy ativas)
- A chave SSH é gerada automaticamente pelo Terraform (provider `tls`) e salva como `technova-key.pem`

### Executar

```bash
# Inicializar providers
terraform init

# Validar sintaxe
terraform validate

# Pré-visualizar os recursos
terraform plan

# Criar a infraestrutura
terraform apply
```

### Testar

```bash
# Descobrir a URL da API
terraform output api_url

# Testar a API (aguarde ~2 min após o apply para o user_data terminar)
curl http://<IP_PUBLICO>:3000
curl http://<IP_PUBLICO>:3000/health
curl http://<IP_PUBLICO>:3000/info

# Conectar via SSH
terraform output -raw ssh_command
ssh -i technova-key.pem ec2-user@<IP_PUBLICO>

# Verificar Node e identidade da role no EC2
node --version
aws sts get-caller-identity
```

### Destruir (obrigatório após capturar evidências)

```bash
terraform destroy
```

> ⚠️ Não deixe recursos rodando na AWS após capturar as evidências.

## Decisões Técnicas

- **Multi-AZ (us-east-1a + us-east-1b):** distribuir subnets em duas AZs é a base
  da alta disponibilidade. Se uma AZ cair, a infraestrutura pode continuar operando
  na outra. Também é pré-requisito para um Application Load Balancer, que exige pelo
  menos duas subnets em AZs diferentes.

- **Separação público/privado:** as subnets públicas (com rota para o IGW) hospedam
  recursos que precisam ser acessíveis pela internet (a API). As privadas não têm
  rota para a internet e ficam reservadas para o banco de dados (RDS futuro),
  reduzindo a superfície de ataque — nada no banco fica exposto publicamente.

- **Security Group do banco restrito à VPC:** o SG do PostgreSQL só aceita a porta
  5432 vinda de `10.0.0.0/16`. Assim, mesmo que o banco venha a existir, ele só é
  alcançável de dentro da rede — aplicação do menor privilégio.

- **Instance Profile com S3 read-only:** a EC2 usa uma IAM Role (credenciais
  temporárias e rotacionadas), em vez de access keys embutidas. Permissão mínima:
  apenas leitura no S3.

- **Key Pair gerado via Terraform (`tls_private_key`):** a chave é criada como código
  e salva localmente com permissão `0600`, evitando o passo manual no console.

- **`t2.micro` + AMI via data source:** mantém o ambiente no Free Tier e sempre pega
  a AMI mais recente do Amazon Linux 2023.

## Recursos Criados

| Recurso | Tipo Terraform | Função |
|---------|----------------|--------|
| VPC | `aws_vpc` | Rede isolada 10.0.0.0/16 |
| 2 Subnets públicas | `aws_subnet` | EC2 exposta à internet (2 AZs) |
| 2 Subnets privadas | `aws_subnet` | Reservadas para banco de dados (2 AZs) |
| Internet Gateway | `aws_internet_gateway` | Saída para a internet |
| Route Table pública | `aws_route_table` + associations | Rota 0.0.0.0/0 → IGW nas 2 públicas |
| SG da API | `aws_security_group` | Libera SSH (22) e API (3000) |
| SG do banco | `aws_security_group` | Libera PostgreSQL (5432) só interno |
| IAM Role | `aws_iam_role` | Role assumível pela EC2 |
| Policy attachment | `aws_iam_role_policy_attachment` | AmazonS3ReadOnlyAccess |
| Instance Profile | `aws_iam_instance_profile` | Anexa a role à EC2 |
| Key Pair | `tls_private_key` + `aws_key_pair` | Acesso SSH gerado por código |
| EC2 | `aws_instance` | t2.micro rodando a API Node.js via user_data |

## Outputs Principais

| Output | Descrição |
|--------|-----------|
| `vpc_id` | ID da VPC |
| `public_subnet_ids` / `private_subnet_ids` | IDs das subnets |
| `api_security_group_id` / `db_security_group_id` | IDs dos Security Groups |
| `ec2_public_ip` | IP público da instância |
| `api_url` | `http://<ip>:3000` |
| `ssh_command` | Comando SSH pronto |

## Tags

Aplicadas via `default_tags` no provider, em todos os recursos que suportam tagging:

```hcl
Project     = "TechNova"
Environment = "development"
ManagedBy   = "Terraform"
Owner       = "4025109"
```
