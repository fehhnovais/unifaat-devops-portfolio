// =============================================================================
// TechNova — API de Reserva de Salas de Reunião (Aula 07)
// Node.js + Express | dados em memória (sem banco de dados)
// Aluno: Fernanda Rosa Novais Tavares (RA 4025109)
// =============================================================================

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// ── Armazenamento em memória ────────────────────────────────────────────────
const salas = [];     // { id, nome, capacidade }
const reservas = [];  // { id, salaId, funcionario, inicio, fim }

let proximoSalaId = 1;
let proximoReservaId = 1;

// ── Helpers ──────────────────────────────────────────────────────────────────

// Verifica se dois intervalos [inicioA, fimA) e [inicioB, fimB) se sobrepõem.
// Usa timestamps para comparar. Retorna true se há conflito.
function intervalosSobrepoem(inicioA, fimA, inicioB, fimB) {
  return inicioA < fimB && inicioB < fimA;
}

// Converte string de data/hora para timestamp. Retorna NaN se inválida.
function paraTimestamp(valor) {
  return new Date(valor).getTime();
}

// ── Rotas: Salas ───────────────────────────────────────────────────────────

// POST /salas — cadastrar uma sala (nome obrigatório)
app.post('/salas', (req, res) => {
  const { nome, capacidade } = req.body || {};

  if (!nome || typeof nome !== 'string' || nome.trim() === '') {
    return res.status(400).json({ erro: 'O campo "nome" é obrigatório.' });
  }

  const sala = {
    id: proximoSalaId++,
    nome: nome.trim(),
    capacidade: capacidade || null,
  };
  salas.push(sala);

  return res.status(201).json(sala);
});

// GET /salas — listar as salas cadastradas
app.get('/salas', (req, res) => {
  return res.json(salas);
});

// ── Rotas: Reservas ──────────────────────────────────────────────────────────

// POST /reservas — criar uma reserva (sala, funcionário, horário)
// Impede conflito: não permite duas reservas na mesma sala em horários sobrepostos.
app.post('/reservas', (req, res) => {
  const { salaId, funcionario, inicio, fim } = req.body || {};

  // Validação dos campos obrigatórios
  if (salaId === undefined || salaId === null) {
    return res.status(400).json({ erro: 'O campo "salaId" é obrigatório.' });
  }
  if (!funcionario || typeof funcionario !== 'string' || funcionario.trim() === '') {
    return res.status(400).json({ erro: 'O campo "funcionario" é obrigatório.' });
  }
  if (!inicio || !fim) {
    return res.status(400).json({ erro: 'Os campos "inicio" e "fim" são obrigatórios.' });
  }

  // A sala precisa existir
  const sala = salas.find((s) => s.id === Number(salaId));
  if (!sala) {
    return res.status(404).json({ erro: `Sala ${salaId} não encontrada.` });
  }

  // Validação de horário
  const inicioTs = paraTimestamp(inicio);
  const fimTs = paraTimestamp(fim);
  if (Number.isNaN(inicioTs) || Number.isNaN(fimTs)) {
    return res.status(400).json({ erro: 'Datas de "inicio" e "fim" inválidas. Use formato ISO 8601.' });
  }
  if (fimTs <= inicioTs) {
    return res.status(400).json({ erro: 'O "fim" deve ser posterior ao "inicio".' });
  }

  // Bloqueio de conflito — verifica sobreposição com reservas existentes da mesma sala
  const conflito = reservas.find((r) => {
    if (r.salaId !== Number(salaId)) return false;
    return intervalosSobrepoem(inicioTs, fimTs, paraTimestamp(r.inicio), paraTimestamp(r.fim));
  });

  if (conflito) {
    return res.status(409).json({
      erro: 'Conflito de horário: já existe uma reserva para esta sala neste período.',
      reservaConflitante: conflito,
    });
  }

  const reserva = {
    id: proximoReservaId++,
    salaId: Number(salaId),
    funcionario: funcionario.trim(),
    inicio,
    fim,
  };
  reservas.push(reserva);

  return res.status(201).json(reserva);
});

// GET /reservas?funcionario=NOME — listar reservas de um funcionário
// Sem query, lista todas as reservas.
app.get('/reservas', (req, res) => {
  const { funcionario } = req.query;

  if (funcionario) {
    const doFuncionario = reservas.filter(
      (r) => r.funcionario.toLowerCase() === String(funcionario).toLowerCase()
    );
    return res.json(doFuncionario);
  }

  return res.json(reservas);
});

// DELETE /reservas/:id — cancelar uma reserva
app.delete('/reservas/:id', (req, res) => {
  const id = Number(req.params.id);
  const indice = reservas.findIndex((r) => r.id === id);

  if (indice === -1) {
    return res.status(404).json({ erro: `Reserva ${id} não encontrada.` });
  }

  const [removida] = reservas.splice(indice, 1);
  return res.json({ mensagem: 'Reserva cancelada com sucesso.', reserva: removida });
});

// ── Rota raiz / health ────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    servico: 'TechNova — API de Reserva de Salas',
    aula: '07 - Spec-Driven',
    rotas: [
      'POST /salas',
      'GET /salas',
      'POST /reservas',
      'GET /reservas?funcionario=NOME',
      'DELETE /reservas/:id',
    ],
  });
});

// ── Inicialização ──────────────────────────────────────────────────────────────
// Só sobe o servidor se executado diretamente (permite testes/import futuros)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`API de Reserva de Salas rodando na porta ${PORT}`);
  });
}

module.exports = app;
