# Screenshots — Evidências da Aula 09

Adicione aqui os 4 screenshots obrigatórios:

| Arquivo | O que capturar |
|---------|----------------|
| `ecr-console.png` | Console do Amazon ECR, repositório `technova-api`, mostrando as tags (`sha-...`, `latest`, e o semver `1.2.3`/`1.2`/`1` se publicou com git tag) |
| `ai-review-comment.png` | Comentário do AI review num PR, com a tabela de achados por severidade |
| `ecr-push-ok.png` | Terminal com `./ecr-push.sh` concluído (`✅ Push concluído`) OU o workflow `CI ECR Aula 09` verde |
| `quality-gate-block.png` | PR bloqueado pelo quality gate — check `AI Review + Quality Gate` vermelho por achado CRITICAL |

## Como gerar o quality gate bloqueando (para o screenshot)

1. Crie uma branch e adicione um arquivo com um problema CRITICAL em `aula-09/`, por exemplo
   uma linha com `const apiKey = "sk-exemplo-123456";` ou `eval(input);`
2. Faça push e abra um PR para a `main`
3. O workflow `AI Review + Quality Gate` roda, posta o comentário com o achado e **falha**
4. Tire o print do check vermelho e do comentário
5. Feche o PR sem merge e apague a branch

## Como gerar as evidências do ECR

1. Abra o AWS Academy Learner Lab e carregue as credenciais da sessão (`us-east-1`)
2. Rode `./ecr-push.sh` na pasta `aula-09/`
3. Print do terminal ao final (`ecr-push-ok.png`)
4. No console AWS → Elastic Container Registry → `technova-api` → print das tags (`ecr-console.png`)
