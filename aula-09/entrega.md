# Entrega — Aula 09: Docker Registry e IA no CI/CD

**Aluno:** FERNANDA TAVARES
**RA:** 4025109
**Data:** [preencher na entrega]

## Repositório

- URL: https://github.com/fehhnovais/unifaat-devops-portfolio
- Projeto: `aula-09/`
- Workflows: `.github/workflows/ai-review-aula09.yml` e `.github/workflows/ci-ecr-aula09.yml`

## Evidências

- [x] Script `ecr-push.sh` executado: cria repo, login, build OK — push bloqueado por SCP do Lab (ver nota)
- [x] Repositório ECR `technova-api` criado no Learner Lab (`us-east-1`)
- [ ] Pull da imagem a partir do ECR — não possível (push bloqueado pela SCP da organização)
- [x] Workflow de AI Review disparando em PRs
- [x] Quality gate (CRITICAL bloqueia o PR)
- [x] `ia-cicd-analise.md` preenchido (inclui a limitação da SCP)
- [ ] Screenshots (AI review, gate bloqueando, log do ecr-push.sh)

## Nota sobre o Amazon ECR

O `ecr-push.sh` rodou com a sessão do Learner Lab ativa e executou todo o fluxo: criação do
repositório `technova-api` (scan-on-push), lifecycle policy, login (`Login Succeeded`) e build
da imagem. O **push das camadas foi bloqueado** pela policy da organização do AWS Academy:

```
is not authorized to perform: ecr:UploadLayerPart ... explicit deny in a
service control policy: .../p-3p1n4vnd
```

É uma restrição do ambiente (o Lab permite criar o repo, mas nega o upload de imagens), não um
erro do script ou das credenciais. Detalhes em `ia-cicd-analise.md`.

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
