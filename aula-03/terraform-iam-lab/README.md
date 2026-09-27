# Aula 03 — Terraform + IAM | Fernanda Rosa Novais Tavares (RA 4025109)

Estrutura completa de IAM da TechNova provisionada com Terraform, seguindo o
princípio do menor privilégio. Inclui groups, users, custom policies com
Conditions e Deny explícito, além de uma service role para EC2 acessar o S3.

## Design da Estrutura IAM

A estrutura foi desenhada em torno de **três times com necessidades distintas**,
usando groups como ponto único de atribuição de permissões (nenhuma policy é
anexada diretamente a um user). Isso mantém o controle de acesso centralizado e
fácil de auditar: para saber o que uma pessoa pode fazer, basta olhar os groups
dela.

### Groups (`groups.tf`)

| Group | Propósito |
|-------|-----------|
| `technova-developers` | Todos os desenvolvedores — acesso de leitura ao S3 de dados |
| `technova-platform-eng` | Time de infraestrutura — gerencia EC2 marcado como TechNova |
| `technova-interns` | Estagiários — leitura restrita com Deny explícito de ações destrutivas |

> Groups do IAM não suportam tags na AWS, por isso não há bloco `tags` neles.

### Users e memberships (`users.tf`)

| User | Groups |
|------|--------|
| `juliana.santos` | developers |
| `rafael.oliveira` | developers + platform-eng |
| `lucas.intern` | developers + interns |

O Rafael participa de dois groups porque acumula os papéis de dev e de infra — as
permissões se somam. O Lucas está em `developers` e `interns`: mesmo herdando a
leitura de dev, o **Deny explícito** da policy de estagiário prevalece e bloqueia
qualquer ação destrutiva.

### Policies (`policies.tf`)

| Policy | Efeito | O que permite / nega |
|--------|--------|----------------------|
| `technova-developer-policy` | Allow | `s3:GetObject`, `s3:ListBucket`, `s3:GetBucketLocation` restrito a `technova-dados-*` |
| `technova-platform-eng-policy` | Allow + Condition | Start/Stop/Reboot de EC2 **apenas** em instâncias com tag `Project=TechNova`; Describe global |
| `technova-intern-policy` | Allow + **Deny** | Leitura de S3/EC2, com Deny explícito para `s3:DeleteObject`, `s3:PutObject`, `ec2:TerminateInstances`, `ec2:StopInstances`, `ec2:ModifyInstanceAttribute` |

### Service Role para EC2 (`roles.tf`)

- **Role** `technova-ec2-s3-access-role` com trust policy permitindo que o
  serviço `ec2.amazonaws.com` assuma a role (`sts:AssumeRole`).
- **Permissions**: read/write em `technova-app-data-*` (inline policy).
- **Instance Profile** `technova-ec2-s3-instance-profile` para anexar a role à EC2.

Assim a EC2 recebe **credenciais temporárias e rotacionadas automaticamente**,
sem access keys embutidas no código ou na instância.

## Princípio do Menor Privilégio

O princípio do menor privilégio diz que cada identidade deve receber **apenas as
permissões estritamente necessárias** para sua função — nada além disso.

Dois exemplos concretos aplicados neste código:

1. **Developers só leem, e só o bucket certo.** Em vez de dar `AmazonS3FullAccess`,
   a policy libera apenas `GetObject`/`ListBucket` e restringe os recursos ao
   padrão `technova-dados-*`. Um dev não consegue apagar objetos nem tocar em
   buckets de outros projetos.

2. **Platform Eng só age em recursos etiquetados.** A `Condition`
   `ec2:ResourceTag/Project = TechNova` garante que o time de infra só liga/desliga
   instâncias do próprio projeto, mesmo que a conta tenha EC2 de outras equipes.

**E se eu usasse `AmazonS3FullAccess` no lugar da custom policy?** Qualquer user do
group poderia ler, escrever e **apagar objetos em qualquer bucket da conta** —
incluindo backups e dados de produção de outros times. Um clique errado ou uma
credencial vazada viraria um incidente de segurança. A custom policy limita o
"raio de explosão" a um subconjunto pequeno e previsível de recursos.

## Diagrama de Permissões

```
Users                Groups                    Policies                         Recursos
-----                ------                    --------                         --------
juliana.santos ──┐
                 ├─▶ technova-developers ────▶ developer-policy (Allow) ──────▶ s3: technova-dados-*
rafael.oliveira ─┤                                                              (GetObject, ListBucket)
                 │
                 └─▶ technova-platform-eng ──▶ platform-eng-policy ───────────▶ ec2: instâncias com
                     (só rafael)               (Allow + Condition tag)           Project=TechNova
lucas.intern ────┬─▶ technova-developers
                 └─▶ technova-interns ───────▶ intern-policy ─────────────────▶ Deny: Delete/Terminate/
                                               (Allow leitura + Deny)             Stop/Put/Modify

Service Role (EC2 → S3)
-----------------------
EC2 ──assume──▶ technova-ec2-s3-instance-profile ──▶ technova-ec2-s3-access-role
                                                     (trust: ec2.amazonaws.com)
                                                     └─▶ s3: technova-app-data-* (read/write)
```

## Comandos Utilizados

```bash
terraform init      # inicializa o provider AWS
terraform fmt       # formata os arquivos .tf
terraform validate  # valida a sintaxe e as referências
terraform plan      # pré-visualiza os recursos a serem criados
terraform apply     # cria os recursos IAM na conta
terraform destroy   # remove tudo após capturar as evidências
```

> No AWS Academy, o IAM é gratuito e pode ser testado à vontade. Ainda assim,
> rode `terraform destroy` ao final para não deixar recursos órfãos.

## Reflexão — Console AWS manual vs. Terraform

Criar IAM manualmente pelo Console funciona para um recurso isolado, mas não
escala e não deixa rastro. Cada clique é uma ação sem histórico: ninguém sabe
quem criou aquela policy, quando, ou por quê. Reproduzir o mesmo ambiente em outra
conta vira um trabalho manual sujeito a erros e esquecimentos.

Com Terraform, toda a estrutura vira **código versionado no Git**. As vantagens
para uma equipe são diretas:

- **Auditabilidade**: o histórico do Git mostra exatamente o que mudou, quem
  alterou e em qual commit. Um `git blame` responde "por que essa permissão
  existe?".
- **Revisão antes de aplicar**: mudanças passam por Pull Request; o `terraform plan`
  mostra o impacto antes de qualquer coisa acontecer na conta.
- **Reprodutibilidade**: o mesmo código recria a estrutura idêntica em dev, staging
  ou prod, eliminando o "funciona na minha conta".
- **Menos erro humano**: a Condition por tag e o Deny explícito ficam garantidos em
  código, não dependem de alguém lembrar de configurá-los no Console.

Para uma equipe, o Terraform é claramente **mais seguro e auditável**: transforma
gestão de acesso em algo revisável, versionado e repetível — exatamente o que se
espera de segurança em ambiente de nuvem.

## Estrutura de Arquivos

```
terraform-iam-lab/
├── providers.tf     # provider AWS + default_tags (tags obrigatórias)
├── variables.tf     # project_name, aluno, ra, disciplina, aula, region
├── groups.tf        # 3 IAM groups
├── users.tf         # 3 IAM users + memberships
├── policies.tf      # 3 custom policies (Condition + Deny explícito)
├── attachments.tf   # policy → group attachments
├── roles.tf         # service role EC2 + instance profile
├── outputs.tf       # ARNs de users, groups, policies, role e profile
├── SPEC.md          # especificação técnica detalhada
└── README.md        # este arquivo
```

## Tags Obrigatórias

Aplicadas via `default_tags` no provider, portanto presentes em todos os recursos
que suportam tagging (users, policies, roles, instance profile):

```hcl
Project    = "TechNova"
ManagedBy  = "Terraform"
Aluno      = "Fernanda Rosa Novais Tavares"
RA         = "4025109"
Disciplina = "DevOps - UniFAAT 2026-2"
Aula       = "03"
```
