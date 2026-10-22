# TechNova API — Aula 09 (Amazon ECR + AI Review no CI/CD)

![AI Review](https://github.com/fehhnovais/unifaat-devops-portfolio/actions/workflows/ai-review-aula09.yml/badge.svg)

Pipeline que **builda**, **publica no Amazon ECR** e **revisa código com IA** automaticamente
em cada Pull Request, com quality gate que bloqueia problemas críticos.

> **Aluno:** FERNANDA TAVARES — **RA:** 4025109

---

## Estrutura

```
aula-09/
├── app/
│   ├── server.js              # TechNova API (Express)
│   └── package.json           # versão 1.2.3 (usada no semver)
├── .github/
│   ├── workflows/             # cópias de referência (as que rodam ficam na raiz do repo)
│   │   ├── ci.yml
│   │   └── ai-review.yml
│   └── scripts/
│       └── ai-review.js       # análise de IA (10 regras) + quality gate
├── Dockerfile                 # multi-stage (deps → runtime), não-root, healthcheck
├── .dockerignore
├── ecr-push.sh                # fluxo principal: cria repo, login, build, push (sha/latest/semver)
├── ecr-lifecycle-policy.json  # lifecycle policy do ECR (bônus)
├── ia-cicd-analise.md         # documentação da estratégia
├── entrega.md                 # modelo de entrega para o fork
├── screenshots/               # evidências
└── README.md
```

> ⚠️ Os workflows que o GitHub Actions executa ficam na **raiz do repositório**:
> `.github/workflows/ai-review-aula09.yml` e `.github/workflows/ci-ecr-aula09.yml`.
> O GitHub não roda workflows dentro de subpastas como `aula-09/`.

---

## Parte 1 — Publicar no Amazon ECR (fluxo principal)

Pré-requisitos: **AWS CLI v2**, **Docker**, **git** e a sessão do **Learner Lab** ativa
(credenciais temporárias carregadas, com `aws_session_token`), região `us-east-1`.

```bash
cd aula-09
chmod +x ecr-push.sh
./ecr-push.sh
```

O script:
1. Descobre o Account ID (`aws sts get-caller-identity`)
2. Cria/garante o repositório `technova-api` (idempotente, com scan-on-push)
3. Aplica a lifecycle policy (bônus)
4. Faz login no ECR
5. Builda a imagem
6. Faz push com tags `sha-<short>`, `latest` e semver (se houver git tag `v*.*.*`)

### Publicar uma versão semver

```bash
git tag v1.2.3
./ecr-push.sh          # publica também 1.2.3, 1.2 e 1
```

### Pull / rollback por tag

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
URI=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/technova-api
docker pull $URI:sha-a1b2c3d     # volta a uma versão específica
docker pull $URI:latest
```

### Opcional (Parte 7) — push via GitHub Actions

O workflow `ci-ecr-aula09.yml` faz o mesmo no CI usando
`aws-actions/configure-aws-credentials@v4` + `aws-actions/amazon-ecr-login@v2`.
Configure os 3 secrets **antes de cada sessão** (eles expiram):
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`.

---

## Parte 2 — AI Review em Pull Requests

O workflow `ai-review-aula09.yml` dispara em PRs que tocam `aula-09/`:

1. Gera o diff do PR (`git diff base...HEAD`)
2. Roda `ai-review.js`, que analisa as linhas adicionadas (10 regras)
3. Posta/atualiza um comentário no PR com a tabela de achados
4. **Quality gate:** se houver CRITICAL → o workflow falha → PR bloqueado

### Testar o AI review localmente

```bash
cd aula-09
git diff origin/main...HEAD -- 'aula-09/**' > pr.diff
node .github/scripts/ai-review.js pr.diff
echo $?    # 1 se houver CRITICAL, 0 caso contrário
```

Regras detectadas: secret hardcoded, `eval()`, SQL injection, child_process, `console.log`,
catch vazio, `http://` inseguro, `debugger`, TODO/FIXME e `var`.

---

## Bônus implementados

- ✅ Lifecycle policy no ECR (`ecr-lifecycle-policy.json`)
- ✅ Scan on push habilitado na criação do repositório
- ✅ Comentário atualizado (não duplicado) a cada push no PR (via marcador HTML)
- ✅ Mais de 8 padrões detectados (10 regras)
- ✅ Badge de status no README
- ✅ Dockerfile multi-stage, não-root, com healthcheck
