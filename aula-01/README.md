# Aula 01 — Fundamentos de Git e Docker

## O que aprendi

- [Descreva 3-5 conceitos que aprendeu sobre Git]
- [Descreva 3-5 conceitos que aprendeu sobre Docker]

## Comandos Git praticados

- [Liste os comandos Git que utilizou]
git init
git status
git add
git commit
git branch
git remote
git push

## Comandos Docker praticados

- [Liste os comandos Docker que utilizou]

docker build
docker run
docker ps
docker stop

## Como executar este container

```bash
cd aula-01/app
docker build -t portfolio-aula01:1.0 .
docker run -d -p 3000:3000 portfolio-aula01:1.0
curl http://localhost:3000



