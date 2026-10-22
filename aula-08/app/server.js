const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

// Secret referenciado via env (populado pelo GitHub Secrets no CI)
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';

app.use(express.json());

// Base de dados em memória (simulação de pedidos da TechNova)
const orders = [
  { id: 1, cliente: 'Ana Souza', total: 250.0, status: 'pago' },
  { id: 2, cliente: 'Bruno Lima', total: 99.9, status: 'pendente' },
  { id: 3, cliente: 'Carla Dias', total: 1540.5, status: 'enviado' }
];

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    uptime: process.uptime(),
    region: AWS_REGION,
    timestamp: new Date().toISOString()
  });
});

// Endpoint raiz
app.get('/', (req, res) => {
  res.status(200).json({
    servico: 'TechNova API - Aula 08 (CI com GitHub Actions)',
    aluno: 'FERNANDA TAVARES',
    ra: '4025109',
    versao: '1.0.0',
    endpoints: ['/health', '/api/orders', '/api/orders/:id']
  });
});

// Lista de pedidos
app.get('/api/orders', (req, res) => {
  res.status(200).json(orders);
});

// Pedido por id
app.get('/api/orders/:id', (req, res) => {
  const id = Number(req.params.id);
  const order = orders.find((o) => o.id === id);

  if (!order) {
    return res.status(404).json({ erro: 'Pedido não encontrado' });
  }

  return res.status(200).json(order);
});

// Criação de pedido
app.post('/api/orders', (req, res) => {
  const { cliente, total } = req.body;

  if (!cliente || typeof total !== 'number') {
    return res.status(400).json({ erro: 'cliente e total (number) são obrigatórios' });
  }

  const novo = {
    id: orders.length + 1,
    cliente,
    total,
    status: 'pendente'
  };
  orders.push(novo);

  return res.status(201).json(novo);
});

// Inicia o servidor apenas quando executado diretamente (não durante os testes)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`TechNova API rodando na porta ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
  });
}

module.exports = app;
