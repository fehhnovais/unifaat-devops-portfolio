# Processo Spec-Driven — Reserva de Salas | Fernanda Rosa Novais Tavares (RA 4025109)

## 1. Como eu dividi o problema

O enunciado junta várias capacidades numa frase só (cadastrar salas, listar,
reservar, evitar conflito, cancelar, listar por funcionário). Em vez de pedir
tudo de uma vez, quebrei em partes pequenas e independentes, cada uma testável
isoladamente:

1. **Fundação** — projeto Node/Express, servidor subindo, armazenamento em memória
2. **Cadastrar sala** (`POST /salas`) com validação de nome obrigatório
3. **Listar salas** (`GET /salas`)
4. **Criar reserva** (`POST /reservas`) — o "caminho feliz", ainda sem conflito
5. **Bloquear conflito de horário** — a parte mais difícil, isolada de propósito
6. **Cancelar reserva** (`DELETE /reservas/:id`)
7. **Listar reservas por funcionário** (`GET /reservas?funcionario=NOME`)

A ordem é proposital: as salas vêm antes das reservas, porque uma reserva depende
de uma sala existir. E o bloqueio de conflito ficou como um passo **separado** de
"criar reserva", porque misturar as duas coisas de uma vez é onde a IA mais erra.

## 2. Requisitos (o quê)

Requisitos que a sessão Spec ajudou a explicitar:

- Uma **sala** tem nome (obrigatório) e capacidade (opcional).
- Uma **reserva** liga uma sala, um funcionário e um intervalo de tempo (início e fim).
- Não pode haver **duas reservas sobrepostas na mesma sala**.
- Cancelar uma reserva deve removê-la; cancelar id inexistente deve dar erro claro.
- Listar reservas por funcionário deve filtrar corretamente.
- Sem banco de dados: tudo em memória.

**O que precisei corrigir/adicionar:** a primeira interpretação tratava "horário"
como um campo único (ex.: `"09:00"`). Corrigi para **início e fim** — sem os dois
não dá para detectar sobreposição. Também adicionei validações que não estavam
explícitas no enunciado, mas são necessárias:

- A sala precisa **existir** antes de reservar (senão retorna 404).
- `fim` precisa ser **posterior** ao `inicio` (senão 400).
- Datas inválidas devem ser rejeitadas (400), em vez de gerar reservas silenciosas.

## 3. Design (como)

Design proposto e mantido simples de propósito:

- **Um único `server.js`** com Express. O problema é pequeno o suficiente para não
  precisar de camadas (controllers/services/repos separados). Separar aqui seria
  complexidade sem retorno.
- **Dados em memória**: dois arrays, `salas[]` e `reservas[]`, com contadores de id
  auto-incrementais (`proximoSalaId`, `proximoReservaId`).
- **Conflito de horário isolado numa função pura** `intervalosSobrepoem(aInicio,
  aFim, bInicio, bFim)`, que aplica a condição clássica de sobreposição de
  intervalos meio-abertos:

  ```
  inicioA < fimB  E  inicioB < fimA
  ```

  Isolar a regra numa função facilitou testar só ela e evitou espalhar lógica de
  data pelo handler.
- **Códigos HTTP corretos**: 201 (criado), 400 (validação), 404 (não encontrado),
  409 (conflito). Isso deixa os erros claros para quem consome a API.

**Simplificação:** descartei a ideia inicial de validar formatos de data com regex
manual. Usei `new Date(valor).getTime()` e testei por `NaN` — mais simples e
suficiente para o escopo.

## 4. Tarefas (os passos pequenos)

```
[x] Tarefa 1 — Setup: package.json, express, server.js sobe na porta 3000
[x] Tarefa 2 — POST /salas com validação de nome obrigatório
[x] Tarefa 3 — GET /salas lista as salas
[x] Tarefa 4 — POST /reservas (caminho feliz): valida campos, sala existe, fim > inicio
[x] Tarefa 5 — Bloqueio de conflito: rejeita reservas sobrepostas na mesma sala (409)
[x] Tarefa 6 — DELETE /reservas/:id cancela; 404 se não existe
[x] Tarefa 7 — GET /reservas?funcionario=NOME filtra por funcionário
```

## 5. Implementação e validação

Testei cada tarefa antes de seguir para a próxima, com o servidor rodando em
`http://localhost:3000`. Abaixo, 4 validações reais (saída resumida do que a API
respondeu):

### Tarefa 2 — cadastrar sala + validação

```bash
POST /salas  {"nome":"Sala Azul","capacidade":8}
→ 201  {"id":1,"nome":"Sala Azul","capacidade":8}

POST /salas  {"capacidade":4}          # sem nome
→ 400  {"erro":"O campo \"nome\" é obrigatório."}
```
Confirmado: cria com nome e rejeita sem nome.

### Tarefa 4 — criar reserva (caminho feliz)

```bash
POST /reservas  {"salaId":1,"funcionario":"Fernanda",
                 "inicio":"2026-10-01T09:00:00","fim":"2026-10-01T10:00:00"}
→ 201  {"id":1,"salaId":1,"funcionario":"Fernanda", ...}
```
Confirmado: reserva criada quando a sala existe e o horário é válido.

### Tarefa 5 — bloqueio de conflito (a mais crítica)

Testei os três casos que definem se a regra está certa:

```bash
# Reserva A na sala 3: 14:00-15:00  → 201 criada
# ADJACENTE 15:00-16:00 (encosta mas não sobrepõe) → 201 criada  ✅
# SOBREPOSTA 14:30-15:30 (invade a faixa 14:00-15:00) → 409 bloqueada  ✅
```
Confirmado: intervalos que só se **encostam** são permitidos; intervalos que se
**sobrepõem** são bloqueados. Foi por isso que usei intervalo meio-aberto — se eu
tivesse usado `<=`, a reserva adjacente das 15:00 seria bloqueada por engano.

### Tarefa 7 — filtrar por funcionário

```bash
GET /reservas?funcionario=Carlos
→ 200  [ { "id":2, "funcionario":"Carlos", ... } ]   # só as do Carlos
```
Confirmado: o filtro retorna apenas as reservas do funcionário pedido.

## 6. A IA errou em algum momento?

Sim, e o método Spec ajudou a pegar cedo:

- **Erro de modelagem do horário.** Na primeira passada, o "horário" foi tratado
  como um valor único. Isso tornaria **impossível** detectar sobreposição. Percebi
  ao chegar na tarefa 5 (conflito) e ver que não havia como comparar faixas. Corrigi
  o requisito para `inicio` + `fim` e refiz o handler de reserva.
- **Risco de fronteira no conflito (`<` vs `<=`).** A tentação era bloquear quando
  `inicioA <= fimB`. Testando o caso adjacente (uma reserva termina 15:00 e outra
  começa 15:00), vi que `<=` bloquearia algo que deveria ser permitido. Mantive `<`
  (intervalo meio-aberto) e validei com o teste real.

O que evitou alucinação foi **isolar o conflito como uma tarefa própria e testá-la
com casos de fronteira** — em vez de aceitar "parece certo" sem rodar.

## 7. Reflexão

Se eu tivesse pedido "faça a API inteira de uma vez", muito provavelmente teria
recebido um `server.js` que *parece* completo, mas com a modelagem de horário
errada (campo único) — e o bug do conflito só apareceria muito depois, difícil de
rastrear no meio de tudo. É o clássico: quanto maior o pedido, mais a IA preenche
lacunas por conta própria e mais some a chance de você notar.

Dividir o problema mudou o jogo: cada rota virou um passo pequeno com um teste
objetivo (rodar e ver o status HTTP). Quando o conflito de horário — a parte mais
difícil — foi tratado sozinho, ficou fácil pensar nos casos de fronteira
(adjacente vs sobreposto) e confirmar cada um. O aprendizado central é que a IA é
um ótimo copiloto quando **eu** mantenho o controle da decomposição e da validação:
ela escreve rápido, mas quem garante que está certo, testando parte por parte, sou
eu.
