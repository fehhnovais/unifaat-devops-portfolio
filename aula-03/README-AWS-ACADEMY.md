# Terraform com AWS Academy - Guia Completo

## 🤔 Por que usar versão 5.x?

A versão 5.x é a mais recente e tem:
- ✅ Melhores features e correções de bugs
- ✅ Melhor documentação
- ✅ Suporte a recursos AWS mais novos
- ✅ Melhor performance

## ⚠️ O Problema do AWS Provider 5.x com AWS Academy

A partir da versão **4.9.0**, o AWS Provider faz uma chamada automática à API `GetObjectLockConfiguration` ao criar/ler buckets S3.

O AWS Academy **bloqueia** essa API por Service Control Policy (SCP) por motivos de segurança.

**Resultado:** Terraform mostra erro, mas **o bucket É CRIADO com sucesso!**

## ✅ Solução: Workflow Adaptado

### Opção 1: Script Automático (RECOMENDADO)

**Windows (PowerShell):**
```powershell
.\aws-academy-apply.ps1
```

**Linux/WSL (Bash):**
```bash
chmod +x aws-academy-apply.sh
./aws-academy-apply.sh
```

O script faz tudo automaticamente:
1. Aplica o Terraform
2. Detecta o erro de Object Lock
3. Verifica se o bucket foi criado
4. Remove o taint automaticamente
5. Valida o estado final

### Opção 2: Processo Manual

**1. Primeira aplicação (vai dar erro, mas cria os recursos):**
```bash
terraform apply -auto-approve
# ❌ Vai dar erro de GetObjectLockConfiguration
# ✅ MAS os recursos FORAM criados!
```

**2. Verificar recursos criados:**
```bash
aws s3 ls  # Confirma que o bucket existe
terraform state list  # Lista recursos no state
```

**3. Remover taint:**
```bash
terraform untaint aws_s3_bucket.technova_lab
```

**4. Daqui pra frente, sempre use `-refresh=false`:**
```bash
terraform plan -refresh=false
terraform apply -refresh=false -auto-approve
terraform destroy -refresh=false -auto-approve
```

## 🎯 Comandos Essenciais

| Comando | Descrição |
|---------|-----------|
| `terraform plan -refresh=false` | Ver mudanças sem erro |
| `terraform apply -refresh=false -auto-approve` | Aplicar mudanças |
| `terraform destroy -refresh=false -auto-approve` | Destruir recursos |
| `terraform state list` | Listar recursos gerenciados |
| `terraform untaint <recurso>` | Remover marcação de erro |
| `aws s3 ls` | Listar buckets (validar criação) |

## 🔧 Alternativa: Usar Versão 3.x

Se preferir evitar completamente o problema, use a versão 3.x (última antes do bug):

**providers.tf:**
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.76"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  skip_requesting_account_id = true
}
```

Depois:
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
```

## 📊 Comparação de Versões

| Versão | Vantagem | Desvantagem |
|--------|----------|-------------|
| **5.x** | Mais recente, mais features | Precisa de workaround |
| **3.x** | Não tem o bug | Mais antiga, menos features |

## 💡 Recomendação Final

**Use a versão 5.x com o script helper!**

Motivos:
- ✅ É só um inconveniente na primeira aplicação
- ✅ Depois funciona perfeitamente com `-refresh=false`
- ✅ Você aprende a lidar com limitações de ambientes restritivos
- ✅ Código mais moderno e mantido

## 🆘 Troubleshooting

### Erro: "Resource is tainted"
```bash
terraform untaint aws_s3_bucket.technova_lab
```

### Erro: "No credential sources"
```bash
# Copiar credenciais do Windows para WSL
cp /mnt/c/Users/fehhr/.aws/credentials ~/.aws/credentials
chmod 600 ~/.aws/credentials
```

### Bucket foi criado mas não está no state
```bash
terraform import aws_s3_bucket.technova_lab nome-do-bucket
terraform untaint aws_s3_bucket.technova_lab
```

### Sempre dar erro mesmo com -refresh=false
Verifique se está usando a flag corretamente:
```bash
terraform apply -refresh=false -auto-approve
# NÃO: terraform apply -auto-approve -refresh=false
```

## 📚 Referências

- [AWS Provider Issue #23106](https://github.com/hashicorp/terraform-provider-aws/issues/23106)
- [Terraform State Management](https://www.terraform.io/docs/cli/state/index.html)
- [AWS Academy Limitations](https://awsacademy.instructure.com/)
