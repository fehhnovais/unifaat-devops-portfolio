# Screenshots — Evidências da Aula 08

Adicione aqui os 3 screenshots obrigatórios após a primeira execução do pipeline no GitHub:

| Arquivo | O que capturar |
|---------|----------------|
| `screenshot-pipeline-passing.png` | Aba **Actions** com o pipeline completo verde (lint, test, build) |
| `screenshot-pipeline-failing.png` | Pipeline falhando após um erro intencional (ex.: quebrar uma regra do ESLint ou um teste) |
| `screenshot-secrets-configured.png` | Tela **Settings → Secrets → Actions** mostrando o secret `AWS_REGION` (nome visível, valor oculto) |

## Como gerar o pipeline falhando (para o screenshot)

Faça uma alteração que quebre o lint ou um teste, faça push, tire o print da falha na aba
Actions e depois reverta. Exemplo rápido: troque uma aspa simples por aspa dupla em
`app/server.js` (viola a regra `quotes`) → o job `lint` falha.
