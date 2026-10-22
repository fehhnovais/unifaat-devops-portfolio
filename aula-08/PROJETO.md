# TechNova API — Aula 08 (CI com GitHub Actions)

![CI Aula 08](https://github.com/fehhnovais/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml/badge.svg)

Pipeline de Integração Contínua completo para a TechNova API, construído com **GitHub Actions**.
Cada push na `main` e cada Pull Request dispara automaticamente: análise de lint, testes
unitários com coverage e build da imagem Docker.

> **Aluno:** FERNANDA TAVARES — **RA:** 4025109

---

## Estrutura

```
aula-08/
├── app/                       # projeto da aplicação (o CI roda aqui)
│   ├── server.js              # API Express (/health, /api/orders)
│   ├── package.json           # scripts: lint, test (--coverage), start
│   ├── package-lock.json      # lockfile (necessário para npm ci no CI)
│   ├── .eslintrc.json         # regras ESLint (semi, quotes, no-unused-vars)
│   ├── .eslintignore
│   ├── Dockerfile             # imagem node:20-alpine + healthcheck
│   ├── .dockerignore
│   ├── .env.example           # modelo de variáveis (AWS_REGION vem de secret)
│   └── __tests__/
│       └── server.test.js     # 7 testes Jest (4 endpoints)
├── PROJETO.md                 # este arquivo
├── RESPOSTAS.md               # respostas conceituais
├── entrega.md                 # modelo de entrega para o fork da disciplina
└── screenshots/               # evidências do pipeline
```

> ⚠️ O workflow que o GitHub Actions executa fica na **raiz do repositório**, em
> `.github/workflows/ci-aula08.yml`. O GitHub não roda workflows em subpastas, por isso
> ele não fica dentro de `aula-08/`.

---

## Pipeline (lint → test → build)

```
push / pull_request
        │
        ▼
   ┌─────────┐      ┌──────────────────────┐      ┌─────────────────┐
   │  lint   │ ───▶ │ test (Node 18 e 20)  │ ───▶ │ build (Docker)  │
   │ ESLint  │ needs│ Jest + coverage      │ needs│ + smoke test    │
   └─────────┘      └──────────────────────┘      └─────────────────┘
                                                            │
                                                     (em PR) ▼
                                                    ┌─────────────┐
                                                    │ pr-comment  │
                                                    └─────────────┘
```

| Job | O que faz | Requisito |
|-----|-----------|-----------|
| `lint` | Roda ESLint sobre o código | R1, R2 |
| `test` | Jest com `--coverage` em Node 18 e 20 (matrix) | R1, R3, B1 |
| `build` | `docker build` + smoke test no `/health` | R1, R4, B5 |
| `pr-comment` | Comenta o resultado no Pull Request | B3 |

**Secret:** `AWS_REGION` é referenciado via `${{ secrets.AWS_REGION }}` no job `build` (R5).
**Cache:** `setup-node` com `cache: npm` (B2). **Concurrency:** cancela runs antigos (B4).

---

## Rodando localmente

```bash
cd aula-08/app
npm install          # instala dependências
npm run lint         # ESLint
npm test             # Jest com coverage
npm start            # sobe a API em http://localhost:3000

# Docker
docker build -t technova-api .
docker run -p 3000:3000 technova-api
curl http://localhost:3000/health
```

### Resultado da verificação local

| Verificação | Comando | Resultado |
|-------------|---------|-----------|
| Lint | `npm run lint` | ✅ sem erros |
| Testes | `npm test` | ✅ 7/7 passando — coverage ~87% |
| Docker build | `docker build` | ⚠️ não verificado localmente (Docker Desktop offline) — roda no CI |

---

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/` | Informações do serviço |
| GET | `/health` | Health check (status, uptime, region) |
| GET | `/api/orders` | Lista de pedidos |
| GET | `/api/orders/:id` | Pedido por id (404 se não existir) |
| POST | `/api/orders` | Cria pedido (400 se payload inválido) |

---

## Como configurar o secret `AWS_REGION`

1. No GitHub, acesse **Settings → Secrets and variables → Actions**
2. Clique em **New repository secret**
3. Nome: `AWS_REGION` — Valor: `us-east-1` (valor fictício, suficiente para o exercício)
4. Salve. O pipeline passará a referenciá-lo via `${{ secrets.AWS_REGION }}`
