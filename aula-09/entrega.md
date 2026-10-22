# Entrega — Aula 09: Docker Registry e IA no CI/CD

**Aluno:** FERNANDA TAVARES
**RA:** 4025109
**Data:** [preencher na entrega]

## Repositório

- URL: https://github.com/fehhnovais/unifaat-devops-portfolio
- Projeto: `aula-09/`
- Workflows: `.github/workflows/ai-review-aula09.yml` e `.github/workflows/ci-ecr-aula09.yml`

## Evidências

- [ ] Script `ecr-push.sh` publicando no **Amazon ECR** com tags (sha, latest, semver)
- [ ] Repositório ECR `technova-api` criado no Learner Lab (`us-east-1`)
- [ ] Pull da imagem a partir do ECR funcionando (rollback por tag)
- [x] Workflow de AI Review disparando em PRs
- [x] Quality gate (CRITICAL bloqueia o PR)
- [x] `ia-cicd-analise.md` preenchido
- [ ] Screenshots (console ECR com as tags, AI review, pipeline verde, gate bloqueando)

## Bônus

- [x] Lifecycle policy no ECR
- [x] Scan on push habilitado
- [x] Comentário atualizado (não duplicado) nos pushes ao PR
- [x] 10 padrões detectados pelo AI review (> 8)
- [x] Badge de status no README

## Observações

- O push para o ECR depende da sessão ativa do **AWS Academy Learner Lab** (credenciais
  temporárias com `aws_session_token`, região `us-east-1`). O fluxo confiável é o
  `ecr-push.sh` local.
- O AI review e o quality gate foram **testados localmente** (10 achados em diff com
  problemas → exit 1; diff limpo → exit 0).

## Evidência do Pipeline Rodando

[Cole aqui o link da execução ou screenshots]
