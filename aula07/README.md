# TechNova — API de Reserva de Salas de Reunião (Aula 07)

API em Node.js + Express com dados em memória (sem banco de dados). Permite
cadastrar salas, listar salas, criar e cancelar reservas, listar reservas por
funcionário e **impede reservas em conflito de horário** na mesma sala.

- **Aluno:** Fernanda Rosa Novais Tavares
- **RA:** 4025109
- **Tema:** Aula 07 — Decompondo um problema complexo com Spec-Driven

## Como rodar

```bash
cd aula07
npm install
npm start
# API em http://localhost:3000
```

## Rotas

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/salas` | Cadastra uma sala (nome obrigatório) |
| GET | `/salas` | Lista as salas |
| POST | `/reservas` | Cria uma reserva (bloqueia conflito de horário) |
| GET | `/reservas?funcionario=NOME` | Lista reservas de um funcionário |
| DELETE | `/reservas/:id` | Cancela uma reserva |

## Exemplos com curl

### Cadastrar salas
```bash
curl -X POST http://localhost:3000/salas \
  -H "Content-Type: application/json" \
  -d '{"nome":"Sala Azul","capacidade":8}'

curl -X POST http://localhost:3000/salas \
  -H "Content-Type: application/json" \
  -d '{"nome":"Sala Verde"}'
```

### Cadastro sem nome → erro 400
```bash
curl -X POST http://localhost:3000/salas \
  -H "Content-Type: application/json" \
  -d '{"capacidade":4}'
# { "erro": "O campo \"nome\" é obrigatório." }
```

### Listar salas
```bash
curl http://localhost:3000/salas
```

### Criar reserva
```bash
curl -X POST http://localhost:3000/reservas \
  -H "Content-Type: application/json" \
  -d '{"salaId":1,"funcionario":"Fernanda","inicio":"2026-10-01T09:00:00","fim":"2026-10-01T10:00:00"}'
```

### Conflito de horário → erro 409
```bash
# Segunda reserva na mesma sala, horário sobreposto
curl -X POST http://localhost:3000/reservas \
  -H "Content-Type: application/json" \
  -d '{"salaId":1,"funcionario":"Carlos","inicio":"2026-10-01T09:30:00","fim":"2026-10-01T10:30:00"}'
# { "erro": "Conflito de horário: já existe uma reserva para esta sala neste período.", ... }
```

### Listar reservas de um funcionário
```bash
curl "http://localhost:3000/reservas?funcionario=Fernanda"
```

### Cancelar reserva
```bash
curl -X DELETE http://localhost:3000/reservas/1
```

## Estrutura

```
aula07/
├── server.js          # API Express com todas as rotas + lógica de conflito
├── package.json       # dependência: express
├── .gitignore         # ignora node_modules/
├── README.md          # este arquivo
└── processo-spec.md   # documento do processo Spec-Driven (o que mais vale no TF)
```

## Regra de negócio: conflito de horário

Duas reservas conflitam quando são da **mesma sala** e seus intervalos de tempo
se **sobrepõem**. A verificação usa a condição clássica de sobreposição de
intervalos `[a_inicio, a_fim)` e `[b_inicio, b_fim)`:

```
inicioA < fimB  E  inicioB < fimA
```

Se essa condição for verdadeira para alguma reserva existente da mesma sala, a
nova reserva é rejeitada com status `409 Conflict`.
