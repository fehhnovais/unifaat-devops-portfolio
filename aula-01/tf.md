# Aula 01 — Registro da Atividade (Git + Docker)

Documento com o passo a passo executado na atividade da Aula 01: fluxo de Git com
branch de feature e containerização de uma aplicação Express com Docker.

- **Aluno:** Fernanda Rosa Novais Tavares
- **RA:** 4025109
- **Aula:** 01 — Fundamentos de Git e Docker

---

## 1. Fluxo Git

```bash
# Inicializar o repositório e verificar o estado
git init
git status

# Criar uma branch de feature separada da main
git checkout -b feature/aula-01-docker

# Adicionar e commitar as alterações
git add aula-01/
git commit -m "feat(aula-01): app Express + Dockerfile"

# Integrar a feature na main
git checkout main
git merge feature/aula-01-docker

# Configurar o remoto e enviar
git remote add origin <URL_DO_REPOSITORIO>
git push origin main
git push origin feature/aula-01-docker
```

---

## 2. Aplicação (Express)

A aplicação expõe duas rotas:

| Método | Rota      | Retorno                                   |
|--------|-----------|-------------------------------------------|
| GET    | `/`       | Dados do serviço, aluno, RA e status      |
| GET    | `/health` | Status de saúde, uptime e versão          |

Arquivos relevantes:

- `app/server.js` — servidor Express na porta 3000
- `app/package.json` — dependência `express@4.18.2`
- `app/Dockerfile` — imagem baseada em `node:20-alpine`
- `app/.dockerignore` — ignora `node_modules`, `.git`, logs e `.env`

---

## 3. Build e execução com Docker

```bash
cd aula-01/app

# Construir a imagem
docker build -t portfolio-aula01:1.0 .

# Executar o container em segundo plano, expondo a porta 3000
docker run -d -p 3000:3000 --name aula01 portfolio-aula01:1.0

# Verificar containers em execução
docker ps

# Testar os endpoints
curl http://localhost:3000
curl http://localhost:3000/health

# Ver logs e parar o container
docker logs aula01
docker stop aula01
```

---

## 4. Boas práticas aplicadas no Dockerfile

- Imagem base leve (`node:20-alpine`)
- Cópia de `package*.json` **antes** do restante do código, aproveitando o cache de camadas
- `npm install --production` para não instalar dependências de desenvolvimento
- `.dockerignore` para reduzir o contexto de build e evitar copiar arquivos sensíveis
- `EXPOSE 3000` documentando a porta da aplicação

---

## 5. Evidências

As capturas de tela da execução estão em `evidencias.pgn/`:

- `image.png`
- `image-1.png`

---

## 6. Resultado esperado

Ao acessar `http://localhost:3000`, a API responde com um JSON contendo o nome do
serviço, os dados do aluno e o status `online`, comprovando que o container está
rodando corretamente.
